// OpenCode V2 plugin for the Moshi hook daemon.
//
// Port of the plugin written by `moshi-hook install` (v0.3.25). Moshi still
// generates the V1 plugin shape, which OpenCode V2 refuses to load. Remove this
// port when moshi publishes a V2 plugin.
//
// The daemon wire protocol is unchanged. This file only re-registers the same
// behavior on the V2 plugin API: `setup(ctx)` instead of a plugin function that
// returns a hook map.

import { spawnSync } from "node:child_process"
import { readFileSync } from "node:fs"
import { homedir } from "node:os"
import { join as pathJoin } from "node:path"
import { createConnection } from "node:net"
import { Database } from "bun:sqlite"

type AnyRecord = Record<string, unknown>

// ---------------------------------------------------------------------------
// Terminal context
// ---------------------------------------------------------------------------

interface TerminalContext {
  terminalKind: string
  tmuxSession: string
  tmuxWindow: string
  tmuxPane: string
  tmuxSocket: string
  zellijSession: string
  zellijPane: string
  herdrSession: string
  herdrPane: string
  herdrWorkspaceId: string
  herdrWorkspace: string
  herdrTabId: string
  herdrTab: string
}

function tmuxSocketFromEnv(value: string | undefined): string {
  if (!value) return ""
  const idx = value.indexOf(",")
  return idx > 0 ? value.slice(0, idx) : ""
}

function resolveTerminalContext(): TerminalContext {
  const tmuxPane = process.env.TMUX_PANE ?? ""
  const tmuxSocket = tmuxSocketFromEnv(process.env.TMUX)
  let tmuxSession = ""
  let tmuxWindow = ""
  if (process.env.TMUX) {
    const args = ["display-message", "-p"]
    if (tmuxPane) args.push("-t", tmuxPane)
    args.push("#S\t#I")
    try {
      const result = spawnSync("tmux", args, { encoding: "utf8", timeout: 200 })
      const text = typeof result.stdout === "string" ? result.stdout.trim() : ""
      if (text) {
        const parts = text.split("\t", 2)
        tmuxSession = parts[0] ?? ""
        tmuxWindow = parts[1] ?? ""
      }
    } catch {}
  }
  const zellijSession = process.env.ZELLIJ_SESSION_NAME ?? ""
  const zellijPane = process.env.ZELLIJ_PANE_ID ?? ""
  const inHerdr = process.env.HERDR_ENV === "1"
  const herdrSession = inHerdr ? process.env.HERDR_SESSION ?? "" : ""
  const herdrPane = inHerdr ? process.env.HERDR_PANE_ID ?? "" : ""
  const herdrWorkspaceId = inHerdr ? process.env.HERDR_WORKSPACE_ID ?? "" : ""
  const herdrWorkspace = ""
  const herdrTabId = inHerdr ? process.env.HERDR_TAB_ID ?? "" : ""
  const herdrTab = ""
  let terminalKind = ""
  if (tmuxSession) terminalKind = "tmux"
  else if (process.env.HERDR_ENV === "1") terminalKind = "herdr"
  else if (process.env.ZELLIJ || zellijSession || zellijPane) terminalKind = "zellij"
  return {
    terminalKind,
    tmuxSession,
    tmuxWindow,
    tmuxPane,
    tmuxSocket,
    zellijSession,
    zellijPane,
    herdrSession,
    herdrPane,
    herdrWorkspaceId,
    herdrWorkspace,
    herdrTabId,
    herdrTab,
  }
}

const terminalContext = resolveTerminalContext()

function projectNameFromCwd(cwd: string | undefined): string {
  if (!cwd) return ""
  const trimmed = cwd.replace(/\/+$/, "")
  const idx = trimmed.lastIndexOf("/")
  return idx >= 0 ? trimmed.slice(idx + 1) : trimmed
}

function projectNameForCwd(cwd: string | undefined): string {
  return (
    terminalContext.tmuxSession ||
    terminalContext.herdrSession ||
    terminalContext.zellijSession ||
    projectNameFromCwd(cwd)
  )
}

// ---------------------------------------------------------------------------
// Daemon socket
// ---------------------------------------------------------------------------

function resolveSocketPath(): string {
  const override = process.env.MOSHI_SOCKET_PATH
  if (override) return override
  if (process.platform === "darwin") {
    return pathJoin(homedir(), "Library", "Application Support", "Moshi", "moshi-hook.sock")
  }
  if (process.platform === "win32") {
    return "\\\\.\\pipe\\moshi-hook"
  }
  if (process.env.XDG_RUNTIME_DIR) {
    return pathJoin(process.env.XDG_RUNTIME_DIR, "moshi-hook.sock")
  }
  return "/tmp/moshi-hook.sock"
}

interface DaemonResponse {
  type?: string
  decision?: string
  error?: string
}

// Base URL the moshi-hook gateway uses to reach this OpenCode server. The V2
// background service is a real HTTP listener guarded by basic auth. Read its
// advertised address and credentials from the service file so the gateway can
// fetch transcripts.
let moshiServerUrl = ""

function readJSONFile(path: string): AnyRecord | null {
  try {
    const parsed = JSON.parse(readFileSync(path, "utf8"))
    return parsed && typeof parsed === "object" ? (parsed as AnyRecord) : null
  } catch {
    return null
  }
}

function resolveMoshiServerUrl(): string {
  const stateDir =
    process.env.XDG_STATE_HOME ?? pathJoin(homedir(), ".local", "state")
  const service = readJSONFile(pathJoin(stateDir, "opencode", "service.json"))
  if (!service) return ""
  const rawUrl = stringProp(service, "url")
  const password = stringProp(service, "password")
  if (!rawUrl) return ""
  try {
    const url = new URL(rawUrl)
    if (password) {
      url.username = "opencode"
      url.password = password
    }
    return url.toString().replace(/\/+$/, "")
  } catch {
    return ""
  }
}

// One-message-per-connection wire protocol: dial, write one envelope as a JSON
// line, optionally read one response, close. Errors and timeouts resolve to
// null so callers degrade gracefully.
function sendEnvelope(
  envelope: AnyRecord,
  opts: { wait: boolean; waitTimeoutMs?: number },
): Promise<DaemonResponse | null> {
  if (moshiServerUrl && envelope.serverUrl === undefined) envelope.serverUrl = moshiServerUrl
  return new Promise((resolve) => {
    let settled = false
    const finish = (val: DaemonResponse | null) => {
      if (settled) return
      settled = true
      try {
        sock.destroy()
      } catch {}
      resolve(val)
    }

    const sock = createConnection({ path: resolveSocketPath() })
    sock.setNoDelay(true)
    sock.once("error", () => finish(null))

    if (opts.wait && opts.waitTimeoutMs) {
      setTimeout(() => finish(null), opts.waitTimeoutMs).unref?.()
    }

    sock.once("connect", () => {
      sock.write(JSON.stringify(envelope) + "\n")
      if (!opts.wait) {
        sock.end()
      }
    })

    const chunks: Buffer[] = []
    sock.on("data", (b: Buffer) => chunks.push(b))
    const parse = () => {
      if (settled) return
      const text = Buffer.concat(chunks).toString("utf8").trim()
      if (!text) return finish(null)
      try {
        finish(JSON.parse(text.split("\n")[0]) as DaemonResponse)
      } catch {
        finish(null)
      }
    }
    sock.once("end", parse)
    sock.once("close", parse)
  })
}

// ---------------------------------------------------------------------------
// Model context limits
// ---------------------------------------------------------------------------

const modelContextLimits = new Map<string, number>()
let modelLimitsReady: Promise<void> = Promise.resolve()

async function refreshModelLimits(ctx: AnyRecord): Promise<void> {
  try {
    const model = ctx.model as { list?: () => Promise<unknown> } | undefined
    if (!model || typeof model.list !== "function") return
    const models = await model.list()
    if (!Array.isArray(models)) return
    for (const raw of models) {
      if (!raw || typeof raw !== "object") continue
      const info = raw as AnyRecord
      const providerID = stringProp(info, "providerID")
      const modelID = stringProp(info, "modelID", "id")
      const limit = info.limit
      const context =
        limit && typeof limit === "object"
          ? (limit as AnyRecord).context
          : undefined
      if (typeof context !== "number" || context <= 0) continue
      if (providerID) modelContextLimits.set(providerID + "\0" + modelID, context)
      if (modelID) modelContextLimits.set(modelID, context)
    }
  } catch {}
}

// ---------------------------------------------------------------------------
// Context remaining
// ---------------------------------------------------------------------------

function resolveOpenCodeDataDir(): string {
  if (process.env.XDG_DATA_HOME) return pathJoin(process.env.XDG_DATA_HOME, "opencode")
  return pathJoin(homedir(), ".local", "share", "opencode")
}

function numberProp(obj: AnyRecord, key: string): number {
  const val = obj[key]
  return typeof val === "number" && val > 0 ? val : 0
}

function tokenTotal(tokens: unknown): number {
  if (!tokens || typeof tokens !== "object") return 0
  const rec = tokens as AnyRecord
  const direct = ["input", "output", "reasoning"].reduce(
    (sum, key) => sum + (typeof rec[key] === "number" ? (rec[key] as number) : 0),
    0,
  )
  if (direct > 0) return direct
  return typeof rec.total === "number" && rec.total > 0 ? rec.total : 0
}

function contextRemainingFromUsage(used: number, window: number): number {
  if (used <= 0 || window <= 0) return 0
  const usedPct = Math.min(100, Math.floor((used * 100) / window))
  const remaining = 100 - usedPct
  return remaining === 0 ? 1 : remaining
}

function parseModelRef(raw: unknown): { providerID: string; modelID: string } {
  if (typeof raw === "string" && raw.length > 0) {
    try {
      const parsed = JSON.parse(raw)
      if (parsed && typeof parsed === "object") {
        const rec = parsed as AnyRecord
        return {
          providerID: stringProp(rec, "providerID"),
          modelID: stringProp(rec, "id", "modelID"),
        }
      }
    } catch {}
  }
  return { providerID: "", modelID: "" }
}

function windowForModel(providerID: string, modelID: string): number {
  return (
    modelContextLimits.get(providerID + "\0" + modelID) ??
    modelContextLimits.get(modelID) ??
    0
  )
}

function openCodeContextRemainingForSession(sessionID: string | undefined): number {
  if (!sessionID) return 0
  return openCodeContextRemainingFromDB(sessionID)
}

function openCodeContextRemainingFromDB(sessionID: string): number {
  let db: Database | undefined
  try {
    db = new Database(pathJoin(resolveOpenCodeDataDir(), "opencode.db"), { readonly: true })
    const row = db
      .query(
        "select model, tokens_input, tokens_output, tokens_reasoning from session where id = ? limit 1",
      )
      .get(sessionID) as AnyRecord | null
    if (row) {
      const used =
        numberProp(row, "tokens_input") +
        numberProp(row, "tokens_output") +
        numberProp(row, "tokens_reasoning")
      if (used > 0) {
        const model = parseModelRef(row.model)
        const remaining = contextRemainingFromUsage(
          used,
          windowForModel(model.providerID, model.modelID),
        )
        if (remaining > 0) return remaining
      }
    }
    return openCodeContextRemainingFromMessages(db, sessionID)
  } catch {
    return 0
  } finally {
    try {
      db?.close()
    } catch {}
  }
}

function openCodeContextRemainingFromMessages(db: Database, sessionID: string): number {
  try {
    const rows = db
      .query(
        "select data from message where session_id = ? order by time_updated desc limit 20",
      )
      .all(sessionID) as Array<{ data?: string }>
    for (const row of rows) {
      if (!row || typeof row.data !== "string") continue
      let msg: AnyRecord | null = null
      try {
        const parsed = JSON.parse(row.data)
        msg = parsed && typeof parsed === "object" ? (parsed as AnyRecord) : null
      } catch {
        continue
      }
      if (!msg) continue
      const used = tokenTotal(msg.tokens)
      if (used <= 0) continue
      const model = parseModelRef(msg.model ?? {
        providerID: stringProp(msg, "providerID"),
        id: stringProp(msg, "modelID"),
      })
      const remaining = contextRemainingFromUsage(
        used,
        windowForModel(model.providerID, model.modelID),
      )
      if (remaining > 0) return remaining
    }
  } catch {}
  return 0
}

const modelNamesBySession = new Map<string, string>()

function withContextRemaining(
  envelope: AnyRecord,
  sessionID: string | undefined,
): AnyRecord {
  const contextRemaining = openCodeContextRemainingForSession(sessionID)
  if (contextRemaining > 0) envelope.contextRemaining = contextRemaining
  const modelName = sessionID ? modelNamesBySession.get(sessionID) || "" : ""
  if (modelName && envelope.modelName === undefined) envelope.modelName = modelName
  return envelope
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

function stringProp(obj: AnyRecord | undefined, ...keys: string[]): string {
  if (!obj) return ""
  for (const key of keys) {
    const val = obj[key]
    if (typeof val === "string" && val.length > 0) return val
  }
  return ""
}

function subtitleForPermission(name: string): string {
  switch (name) {
    case "bash":
      return "Waiting for command approval"
    case "edit":
      return "Waiting for file edit approval"
    case "external_directory":
      return "Waiting for directory access approval"
    default:
      return "Waiting for approval"
  }
}

// Mirrors internal/cli/hook.go newSessionID — 16 hex chars, used when OpenCode
// hands us an event with no session id.
function newSessionID(): string {
  const buf = new Uint8Array(8)
  crypto.getRandomValues(buf)
  return Array.from(buf, (b) => b.toString(16).padStart(2, "0")).join("")
}

// ---------------------------------------------------------------------------
// Session tracking
// ---------------------------------------------------------------------------

const activeSessions = new Set<string>()
const idlePublishedSessions = new Set<string>()
const lastUserPrompts = new Map<string, string>()
const lastAssistantTitles = new Map<string, string>()
const assistantTextByMessage = new Map<string, string>()
const parentSessionBySession = new Map<string, string>()

function sessionKey(sessionID: string | undefined, cwd: string): string {
  return sessionID && sessionID.length > 0 ? sessionID : "cwd:" + cwd
}

function relatedSessionKeys(sessionID: string | undefined, cwd: string): string[] {
  const keys = [sessionKey(sessionID, cwd), "cwd:" + cwd]
  if (activeSessions.size === 1) {
    for (const key of activeSessions) keys.push(key)
  }
  return Array.from(new Set(keys.filter((key) => key.length > 4)))
}

function firstValue(map: Map<string, string>, keys: string[]): string {
  for (const key of keys) {
    const val = map.get(key)
    if (val) return val
  }
  return ""
}

function markSessionActive(sessionID: string | undefined, cwd: string): void {
  const key = relatedSessionKeys(sessionID, cwd)[0] || sessionKey(sessionID, cwd)
  activeSessions.add(key)
  for (const related of relatedSessionKeys(sessionID, cwd)) {
    idlePublishedSessions.delete(related)
  }
}

function formatUserPrompt(prompt: string): string {
  const text = prompt.trim()
  if (!text) return ""
  return text.length > 200 ? text.slice(0, 197) + "..." : text
}

function rememberUserPrompt(
  sessionID: string | undefined,
  cwd: string,
  prompt: string,
): string {
  const formatted = formatUserPrompt(prompt)
  if (!formatted) return ""
  for (const key of relatedSessionKeys(sessionID, cwd)) {
    lastUserPrompts.set(key, formatted)
  }
  return formatted
}

function rememberAssistantText(
  sessionID: string | undefined,
  cwd: string,
  messageID: string,
  text: string,
  append: boolean,
): void {
  if (!messageID || !text) return
  const next = append ? (assistantTextByMessage.get(messageID) || "") + text : text
  assistantTextByMessage.set(messageID, next)
  const title = next.trim()
  if (title) {
    const clipped = title.length > 80 ? title.slice(0, 77) + "..." : title
    for (const key of relatedSessionKeys(sessionID, cwd)) {
      lastAssistantTitles.set(key, clipped)
    }
  }
}

function sendIdleIfActive(
  eventName: string,
  sessionID: string | undefined,
  cwd: string,
): void {
  const keys = relatedSessionKeys(sessionID, cwd)
  const key = keys.find((candidate) => activeSessions.has(candidate)) || ""
  if (!key || keys.some((candidate) => idlePublishedSessions.has(candidate))) return
  const prompt = firstValue(lastUserPrompts, keys)
  if (!prompt) return
  idlePublishedSessions.add(key)
  sendSessionUpdate(
    eventName,
    sessionID,
    cwd,
    undefined,
    "task_complete",
    firstValue(lastAssistantTitles, keys) || "OpenCode idle",
    prompt,
  )
}

// ---------------------------------------------------------------------------
// Outgoing notifications
// ---------------------------------------------------------------------------

function sendSessionUpdate(
  eventName: string,
  sessionID: string | undefined,
  directory: string,
  toolName?: string,
  category?: string,
  title?: string,
  message?: string,
): void {
  void modelLimitsReady.finally(() => {
    void sendEnvelope(
      withContextRemaining(
        {
          type: "session.update",
          source: "opencode",
          sessionId: sessionID || newSessionID(),
          eventName,
          cwd: directory,
          projectName: projectNameForCwd(directory),
          terminalKind: terminalContext.terminalKind,
          tmuxSession: terminalContext.tmuxSession,
          tmuxWindow: terminalContext.tmuxWindow,
          tmuxPane: terminalContext.tmuxPane,
          tmuxSocket: terminalContext.tmuxSocket,
          zellijSession: terminalContext.zellijSession,
          zellijPane: terminalContext.zellijPane,
          herdrSession: terminalContext.herdrSession,
          herdrPane: terminalContext.herdrPane,
          herdrWorkspaceId: terminalContext.herdrWorkspaceId,
          herdrWorkspace: terminalContext.herdrWorkspace,
          herdrTabId: terminalContext.herdrTabId,
          herdrTab: terminalContext.herdrTab,
          toolName: toolName ?? "",
          category: category ?? "",
          title: title ?? "",
          message: message ?? "",
          requestedAt: new Date().toISOString(),
        },
        sessionID,
      ),
      { wait: false },
    )
  })
}

function sendSessionClosed(
  eventName: string,
  sessionID: string | undefined,
  directory: string,
): void {
  void modelLimitsReady.finally(() => {
    void sendEnvelope(
      {
        type: "session.closed",
        source: "opencode",
        sessionId: sessionID || newSessionID(),
        eventName,
        category: "session_ended",
        cwd: directory,
        projectName: projectNameForCwd(directory),
        terminalKind: terminalContext.terminalKind,
        tmuxSession: terminalContext.tmuxSession,
        tmuxWindow: terminalContext.tmuxWindow,
        tmuxPane: terminalContext.tmuxPane,
        tmuxSocket: terminalContext.tmuxSocket,
        zellijSession: terminalContext.zellijSession,
        zellijPane: terminalContext.zellijPane,
        herdrSession: terminalContext.herdrSession,
        herdrPane: terminalContext.herdrPane,
        herdrWorkspaceId: terminalContext.herdrWorkspaceId,
        herdrWorkspace: terminalContext.herdrWorkspace,
        herdrTabId: terminalContext.herdrTabId,
        herdrTab: terminalContext.herdrTab,
        title: "OpenCode session ended",
        requestedAt: new Date().toISOString(),
      },
      { wait: false },
    )
  })
}

function sendTerminalInputRequired(
  eventName: string,
  data: AnyRecord,
  directory: string,
  title: string,
  fallbackMessage: string,
): void {
  const cwd = directoryFromProperties(data, directory)
  const sessionID = sessionIDFromProperties(data)
  const message = summarizeQuestion(data) || fallbackMessage
  void modelLimitsReady.finally(() => {
    void sendEnvelope(
      withContextRemaining(
        {
          type: "session.update",
          source: "opencode",
          sessionId: sessionID || newSessionID(),
          eventName,
          category: "approval_required",
          cwd,
          projectName: projectNameForCwd(cwd),
          terminalKind: terminalContext.terminalKind,
          tmuxSession: terminalContext.tmuxSession,
          tmuxWindow: terminalContext.tmuxWindow,
          tmuxPane: terminalContext.tmuxPane,
          tmuxSocket: terminalContext.tmuxSocket,
          zellijSession: terminalContext.zellijSession,
          zellijPane: terminalContext.zellijPane,
          herdrSession: terminalContext.herdrSession,
          herdrPane: terminalContext.herdrPane,
          herdrWorkspaceId: terminalContext.herdrWorkspaceId,
          herdrWorkspace: terminalContext.herdrWorkspace,
          herdrTabId: terminalContext.herdrTabId,
          herdrTab: terminalContext.herdrTab,
          title,
          subtitle: "Answer in terminal",
          message,
          requestedAt: new Date().toISOString(),
        },
        sessionID,
      ),
      { wait: false },
    )
  })
}

// ---------------------------------------------------------------------------
// Incoming event helpers
// ---------------------------------------------------------------------------

function summarizeQuestion(data: AnyRecord): string {
  const direct = stringProp(data, "question", "prompt", "message", "text", "title")
  if (direct) return direct
  const nested = data.question ?? data.form
  if (nested && typeof nested === "object") {
    return stringProp(nested as AnyRecord, "question", "prompt", "message", "text", "title")
  }
  return ""
}

function sessionIDFromProperties(props: AnyRecord): string | undefined {
  const direct = stringProp(props, "sessionID", "sessionId")
  if (direct) return direct
  const info = props.info
  if (info && typeof info === "object") {
    return stringProp(info as AnyRecord, "id", "sessionID", "sessionId")
  }
  return undefined
}

function directoryFromProperties(props: AnyRecord, fallback: string): string {
  const direct = stringProp(props, "directory", "cwd")
  if (direct) return direct
  const info = props.info
  if (info && typeof info === "object") {
    const fromInfo = stringProp(info as AnyRecord, "directory", "cwd")
    if (fromInfo) return fromInfo
  }
  return fallback
}

function rememberSessionOrigin(value: AnyRecord): void {
  const info =
    value.info && typeof value.info === "object"
      ? (value.info as AnyRecord)
      : value
  const sessionID =
    stringProp(info, "id", "sessionID", "sessionId") ||
    stringProp(value, "sessionID", "sessionId", "id")
  const parentID =
    stringProp(info, "parentID", "parentId", "parent_id") ||
    stringProp(value, "parentID", "parentId", "parent_id")
  if (sessionID && parentID) parentSessionBySession.set(sessionID, parentID)
}

function isChildSession(sessionID: string | undefined): boolean {
  return !!sessionID && parentSessionBySession.has(sessionID)
}

function statusTypeFromProperties(props: AnyRecord): string {
  const status = props.status
  if (status && typeof status === "object") {
    return stringProp(status as AnyRecord, "type")
  }
  return stringProp(props, "status")
}

function rememberSessionModel(props: AnyRecord): void {
  const sessionID = stringProp(props, "sessionID", "sessionId")
  const model = props.model
  let modelID = stringProp(props, "modelID", "modelId")
  if (!modelID && model && typeof model === "object") {
    modelID = stringProp(model as AnyRecord, "id", "modelID")
  }
  if (sessionID && modelID) modelNamesBySession.set(sessionID, modelID)
}

// ---------------------------------------------------------------------------
// Approval round-trip
// ---------------------------------------------------------------------------

const approvalRequests = new Map<string, Promise<DaemonResponse | null>>()

function approvalName(event: AnyRecord): string {
  return stringProp(event, "action", "permission", "type") || "permission"
}

function summarizeApproval(event: AnyRecord): string {
  const action = approvalName(event)
  const resources = event.resources
  const first =
    Array.isArray(resources) && typeof resources[0] === "string"
      ? resources[0]
      : ""
  if (!first) return action + " permission requested"
  return action + ": " + first
}

function requestMoshiApproval(
  event: AnyRecord,
  directory: string,
): Promise<DaemonResponse | null> {
  const sessionID = stringProp(event, "sessionID", "sessionId")
  const source =
    event.source && typeof event.source === "object"
      ? (event.source as AnyRecord)
      : {}
  const actionID =
    stringProp(source, "id") || sessionID + ":" + approvalName(event) + ":" + newSessionID()

  const existing = approvalRequests.get(actionID)
  if (existing) return existing

  const name = approvalName(event)
  const expiresAt = new Date(Date.now() + 5 * 60_000).toISOString()
  const promise = modelLimitsReady
    .then(() =>
      sendEnvelope(
        withContextRemaining(
          {
            type: "approval.request",
            source: "opencode",
            sessionId: sessionID || newSessionID(),
            actionId: actionID,
            eventName: "permission.ask",
            phase: "waitingForApproval",
            category: "approval_required",
            cwd: directory,
            projectName: projectNameForCwd(directory),
            terminalKind: terminalContext.terminalKind,
            tmuxSession: terminalContext.tmuxSession,
            tmuxWindow: terminalContext.tmuxWindow,
            tmuxPane: terminalContext.tmuxPane,
            tmuxSocket: terminalContext.tmuxSocket,
            zellijSession: terminalContext.zellijSession,
            zellijPane: terminalContext.zellijPane,
            herdrSession: terminalContext.herdrSession,
            herdrPane: terminalContext.herdrPane,
            herdrWorkspaceId: terminalContext.herdrWorkspaceId,
            herdrWorkspace: terminalContext.herdrWorkspace,
            herdrTabId: terminalContext.herdrTabId,
            herdrTab: terminalContext.herdrTab,
            toolName: name,
            title: "OpenCode permission",
            subtitle: subtitleForPermission(name),
            message: summarizeApproval(event),
            expiresAt,
            requestedAt: new Date().toISOString(),
          },
          sessionID,
        ),
        { wait: true, waitTimeoutMs: 5 * 60_000 + 5_000 },
      ),
    )
    .finally(() => {
      approvalRequests.delete(actionID)
    })
  approvalRequests.set(actionID, promise)
  return promise
}

// ---------------------------------------------------------------------------
// Plugin
// ---------------------------------------------------------------------------

export default {
  id: "moshi-hooks",
  async setup(ctx: AnyRecord) {
    const pluginDirectory =
      stringProp((ctx.location as AnyRecord) ?? {}, "directory") || process.cwd()

    moshiServerUrl = resolveMoshiServerUrl()
    modelLimitsReady = refreshModelLimits(ctx)

    await ctx.session.hook("prompt", (event: AnyRecord) => {
      const directory = pluginDirectory
      const sessionID = stringProp(event, "sessionID", "sessionId")
      if (isChildSession(sessionID)) return
      const prompt = event.prompt && typeof event.prompt === "object"
        ? stringProp(event.prompt as AnyRecord, "text")
        : ""
      const formatted = rememberUserPrompt(sessionID, directory, prompt)
      if (!formatted) return
      markSessionActive(sessionID, directory)
      const title =
        firstValue(lastAssistantTitles, relatedSessionKeys(sessionID, directory)) ||
        "OpenCode started"
      sendSessionUpdate(
        "chat.message",
        sessionID,
        directory,
        undefined,
        "session_started",
        title,
        formatted,
      )
    })

    await ctx.tool.hook("execute.before", (event: AnyRecord) => {
      markSessionActive(sessionIDFromProperties(event), pluginDirectory)
    })

    await ctx.tool.hook("execute.after", (event: AnyRecord) => {
      markSessionActive(sessionIDFromProperties(event), pluginDirectory)
    })

    await ctx.permission.hook("evaluate", async (event: AnyRecord) => {
      if (event.effect !== "ask") return
      const result = await requestMoshiApproval(event, pluginDirectory)
      if (!result) return
      if (result.decision === "approve") event.effect = "allow"
      else if (result.decision === "deny") event.effect = "deny"
    })

    const controller = new AbortController()
    void (async () => {
      for await (const raw of ctx.event.subscribe({ signal: controller.signal })) {
        const event = raw as AnyRecord
        try {
          handleEvent(String(event.type ?? ""), event)
        } catch {}
      }
    })()

    return () => controller.abort()

    function handleEvent(type: string, event: AnyRecord): void {
      const data =
        event.data && typeof event.data === "object"
          ? (event.data as AnyRecord)
          : {}
      const location =
        event.location && typeof event.location === "object"
          ? (event.location as AnyRecord)
          : {}
      const directory = stringProp(location, "directory") || pluginDirectory
      const sessionID = sessionIDFromProperties(data)

      rememberSessionOrigin(data)
      if (sessionID && isChildSession(sessionID)) return

      switch (type) {
        case "session.created":
          sendSessionUpdate(
            "session.created",
            sessionID,
            directory,
            undefined,
            "session_started",
            "OpenCode started",
          )
          break
        case "session.text.started":
          break
        case "session.text.delta":
          rememberAssistantText(
            sessionID,
            directory,
            stringProp(data, "assistantMessageID", "messageID"),
            stringProp(data, "delta", "text"),
            true,
          )
          break
        case "session.text.ended":
          rememberAssistantText(
            sessionID,
            directory,
            stringProp(data, "assistantMessageID", "messageID"),
            stringProp(data, "text"),
            false,
          )
          break
        case "message.updated":
          rememberSessionModel(data)
          break
        case "session.status": {
          const statusType = statusTypeFromProperties(data)
          if (statusType === "idle") {
            sendIdleIfActive("session.status", sessionID, directory)
          } else if (statusType) {
            sendSessionUpdate(
              "session.status",
              sessionID,
              directory,
              undefined,
              "",
              "OpenCode started",
              statusType,
            )
          }
          break
        }
        case "session.idle":
          sendIdleIfActive("session.idle", sessionID, directory)
          break
        case "session.deleted":
          if (sessionID) parentSessionBySession.delete(sessionID)
          sendSessionClosed("session.deleted", sessionID, directory)
          break
        case "permission.replied":
        case "permission.rejected":
          sendSessionUpdate(type, sessionID, directory)
          break
        case "form.created":
          sendTerminalInputRequired(
            "form.created",
            data,
            directory,
            "OpenCode needs input",
            "Input requested",
          )
          break
        case "form.replied":
        case "form.cancelled":
          sendSessionUpdate(type, sessionID, directory)
          break
        case "session.error":
          sendTerminalInputRequired(
            "session.error",
            data,
            directory,
            "OpenCode blocked",
            "OpenCode reported an error",
          )
          break
        case "provider.updated":
        case "model.updated":
          modelLimitsReady = refreshModelLimits(ctx)
          break
        default:
          break
      }
    }
  },
}
