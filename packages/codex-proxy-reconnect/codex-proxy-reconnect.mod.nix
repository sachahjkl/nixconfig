_: {
  perSystem = {
    lib,
    pkgs,
    self',
    ...
  }: let
    codexProxyReconnect = pkgs.writeShellApplication {
      name = "codex-proxy-reconnect";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.git
        pkgs.jq
        pkgs.openssh
        pkgs.sops
        pkgs.sqlite
        self'.packages.deploy-rs
        self'.packages.opencode
      ];
      text = ''
                set -euo pipefail

                login=true
                if [ "''${1:-}" = "--use-current" ]; then
                  login=false
                  shift
                fi
                if [ "$#" -ne 0 ]; then
                  printf 'Usage: codex-proxy-reconnect [--use-current]\n' >&2
                  exit 1
                fi

                root=$(git rev-parse --show-toplevel)
                cd "$root"
                if [ ! -f flake.nix ] || [ ! -f secrets/homelab.yaml ]; then
                  printf 'Run this command from the nixconfig repository.\n' >&2
                  exit 1
                fi
        if ! git diff --quiet -- secrets/homelab.yaml || ! git diff --cached --quiet; then
          printf 'The SOPS file and Git index must be clean.\n' >&2
                  exit 1
                fi

        database="''${XDG_DATA_HOME:-$HOME/.local/share}/opencode/opencode.db"
        raw_credential=$(mktemp)
        credential=$(mktemp)
        encoded_credential=$(mktemp)
        deployment_root=""
        cleanup() {
          rm -f "$raw_credential" "$credential" "$encoded_credential"
          if [ -n "$deployment_root" ]; then
            git -C "$root" worktree remove --force "$deployment_root"
          fi
        }
        trap cleanup EXIT
        chmod 600 "$raw_credential" "$credential" "$encoded_credential"

                if $login; then
                  opencode2 auth login OpenAI --method chatgpt-headless
                fi
        sqlite3 -noheader "$database" \
          "select value from credential where integration_id = 'openai' and active = 1 order by time_updated desc limit 1" \
          > "$raw_credential"
        jq -ce '
          select(.type == "oauth")
          | select([.access, .refresh, .metadata.accountID] | all(type == "string" and length > 0))
          | select(.expires | type == "number" and . > 0)
          | {access, refresh, expires, account_id: .metadata.accountID}
        ' "$raw_credential" > "$credential"
        jq -Rs . < "$credential" > "$encoded_credential"

        sops set --value-file secrets/homelab.yaml '["codex-proxy"]["oauth"]' "$encoded_credential"

                git add secrets/homelab.yaml
        git commit -m "Renouveler le credential OAuth du proxy Codex"
        git push origin HEAD

        deployment_root=$(mktemp -d)
        rmdir "$deployment_root"
        git worktree add --detach "$deployment_root" HEAD
        (cd "$deployment_root" && deploy .#homelab)
        git worktree remove "$deployment_root"
        deployment_root=""
                ssh -o BatchMode=yes deploy@homelab sudo -n sh -se <<'REMOTE'
                  systemctl stop codex-proxy.service
                  rm -f /var/lib/codex-proxy/oauth.json
                  systemctl start codex-proxy.service
                  systemctl is-active codex-proxy.service
                  token=$(cat /run/credentials/codex-proxy.service/proxy-token)
                  curl --fail --silent --show-error --max-time 15 \
                    -H "Proxy-Authorization: Bearer $token" \
                    http://127.0.0.1:8083/readyz >/dev/null
        REMOTE
        opencode2 auth logout openai
                printf 'The Codex proxy uses the new OAuth credential.\n'
      '';
    };
  in {
    packages.codex-proxy-reconnect = codexProxyReconnect;
    apps.codex-proxy-reconnect = {
      type = "app";
      program = lib.getExe codexProxyReconnect;
    };
  };
}
