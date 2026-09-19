import { afterAll, expect, test } from "bun:test"
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs"
import { createServer } from "node:net"
import { tmpdir } from "node:os"
import { join } from "node:path"

import {
  handleMoshiPermissionRequest,
  resolveCliPermissionMode,
} from "./moshi-hooks"

const testDirectory = mkdtempSync(join(tmpdir(), "moshi-hooks-"))
const configDirectory = join(testDirectory, "config")
const socketPath = join(testDirectory, "moshi.sock")
const originalConfigHome = process.env.XDG_CONFIG_HOME
const originalInlineConfig = process.env.OPENCODE_CLI_CONFIG_CONTENT
const originalSocketPath = process.env.MOSHI_SOCKET_PATH

afterAll(() => {
  if (originalConfigHome === undefined) delete process.env.XDG_CONFIG_HOME
  else process.env.XDG_CONFIG_HOME = originalConfigHome
  if (originalInlineConfig === undefined) delete process.env.OPENCODE_CLI_CONFIG_CONTENT
  else process.env.OPENCODE_CLI_CONFIG_CONTENT = originalInlineConfig
  if (originalSocketPath === undefined) delete process.env.MOSHI_SOCKET_PATH
  else process.env.MOSHI_SOCKET_PATH = originalSocketPath
  rmSync(testDirectory, { recursive: true, force: true })
})

test("permissions follow the OpenCode CLI mode", async () => {
  mkdirSync(join(configDirectory, "opencode"), { recursive: true })
  process.env.XDG_CONFIG_HOME = configDirectory
  process.env.MOSHI_SOCKET_PATH = socketPath

  writeFileSync(
    join(configDirectory, "opencode", "cli.json"),
    JSON.stringify({ session: { permissions: "autoaccept" } }),
  )
  expect(resolveCliPermissionMode()).toBe("autoaccept")

  const replies: unknown[] = []
  const ctx = {
    permission: {
      reply: async (input: unknown) => {
        replies.push(input)
      },
    },
  }
  const request = {
    id: "per_test",
    sessionID: "ses_test",
    action: "shell",
    resources: ["echo test"],
  }

  await handleMoshiPermissionRequest(ctx, request, testDirectory)
  expect(replies).toEqual([])

  writeFileSync(
    join(configDirectory, "opencode", "cli.json"),
    JSON.stringify({ session: { permissions: "prompt" } }),
  )
  expect(resolveCliPermissionMode()).toBe("prompt")

  const server = createServer((socket) => {
    socket.once("data", () => {
      socket.end(JSON.stringify({ decision: "approve" }) + "\n")
    })
  })
  await new Promise<void>((resolve, reject) => {
    server.once("error", reject)
    server.listen(socketPath, resolve)
  })

  try {
    await handleMoshiPermissionRequest(ctx, request, testDirectory)
  } finally {
    await new Promise<void>((resolve, reject) => {
      server.close((error) => error ? reject(error) : resolve())
    })
  }

  expect(replies).toEqual([
    { sessionID: "ses_test", requestID: "per_test", reply: "once" },
  ])
})
