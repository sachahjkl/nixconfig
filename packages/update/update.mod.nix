_: {
  perSystem = {
    inputs',
    pkgs,
    ...
  }: let
    update = pkgs.writeShellApplication {
      name = "update";
      runtimeInputs = with pkgs; [
        curl
        git
        gnused
        gnutar
        jq
        nix
        nodejs_22
        prefetch-npm-deps
        inputs'.tack.packages.default
      ];
      # Bash `${` is written `''${` inside this Nix string.
      text = ''
        # Update the flake inputs and every package that pins a version by hand.
        # Usage: nix run .#update [target...]
        # Targets: inputs moshi windows-10-theme cf voxl opencode-telegram-bot. Default: all targets.

        root=$(git rev-parse --show-toplevel)
        cd "$root" || exit

        # Print the SRI hash of the file at a URL.
        prefetch_url() {
          nix store prefetch-file --json "$1" | jq -r .hash
        }

        # Apply an extended sed expression in place to a file.
        edit() {
          sed -i -E "$2" "$1"
        }

        update_inputs() {
          tack update
        }

        update_moshi() {
          local file=modules/moshi-hook.mod.nix
          local cdn=https://cdn.getmoshi.app/hook
          local version asset hash
          version=$(curl -fsS "$cdn/latest/version.txt" | tr -d '[:space:]')
          version=''${version#v}
          edit "$file" "s|version = \"[^\"]+\"|version = \"$version\"|"
          for asset in Linux_x86_64 Linux_arm64 Darwin_x86_64 Darwin_arm64; do
            hash=$(prefetch_url "$cdn/v$version/moshi-hook_$asset.tar.gz")
            edit "$file" "/asset = \"moshi-hook_$asset.tar.gz\"/{n;s|hash = \"[^\"]+\"|hash = \"$hash\"|}"
          done
          echo "moshi-hook $version"
        }

        update_voxl() {
          local file=packages/voxl/package.nix
          local repo=tembo/voxl
          local rev hash
          rev=$(curl -fsS "https://api.github.com/repos/$repo/commits/HEAD" | jq -r .sha)
          hash=$(nix flake prefetch --json "github:$repo/$rev" | jq -r .hash)
          edit "$file" "s|rev = \"[^\"]+\"|rev = \"$rev\"|"
          edit "$file" "s|hash = \"[^\"]+\"|hash = \"$hash\"|"
          echo "voxl $rev"
        }

        update_opencode_telegram_bot() {
          local file=services/opencode-telegram-bot.mod.nix
          local repo=grinev/opencode-telegram-bot
          local tag version prefetched hash store_path npm_hash
          tag=$(curl -fsS "https://api.github.com/repos/$repo/releases/latest" | jq -r .tag_name)
          version=''${tag#v}
          prefetched=$(nix flake prefetch --json "github:$repo/$tag")
          hash=$(jq -r .hash <<<"$prefetched")
          store_path=$(jq -r .storePath <<<"$prefetched")
          npm_hash=$(prefetch-npm-deps "$store_path/package-lock.json")
          edit "$file" "s|version = \"[^\"]+\"|version = \"$version\"|"
          edit "$file" "/fetchFromGitHub/,/\};/s|hash = \"[^\"]+\"|hash = \"$hash\"|"
          edit "$file" "s|npmDepsHash = \"[^\"]+\"|npmDepsHash = \"$npm_hash\"|"
          echo "opencode-telegram-bot $version"
        }

        update_windows_10_theme() {
          local file=packages/windows-10-theme/windows-10-theme.mod.nix
          local repo=B00merang-Project/Windows-10-Dark
          local commit rev date hash
          commit=$(curl -fsS "https://api.github.com/repos/$repo/commits/HEAD")
          rev=$(jq -r .sha <<<"$commit")
          date=$(jq -r '.commit.committer.date[:10]' <<<"$commit")
          hash=$(nix flake prefetch --json "github:$repo/$rev" | jq -r .hash)
          edit "$file" "s|version = \"[^\"]+\"|version = \"$date\"|"
          edit "$file" "s|rev = \"[^\"]+\"|rev = \"$rev\"|"
          edit "$file" "s|hash = \"[^\"]+\"|hash = \"$hash\"|"
          echo "windows-10-theme $date ($rev)"
        }

        update_cf() {
          local dir=packages/cf
          local version work
          version=$(curl -fsS https://registry.npmjs.org/cf | jq -r '."dist-tags".latest')
          work=$(mktemp -d)
          trap 'rm -rf "$work"' RETURN

          curl -fsS "https://registry.npmjs.org/cf/-/cf-$version.tgz" -o "$work/cf.tgz"
          tar -xzf "$work/cf.tgz" -C "$work"

          # Keep the runtime dependencies only, like postPatch in cf.mod.nix.
          jq 'del(.devDependencies, .scripts)' "$work/package/package.json" >"$work/package.json"
          mv "$work/package.json" "$work/package/package.json"
          (cd "$work/package" && npm install --package-lock-only --ignore-scripts --no-audit --no-fund)
          cp "$work/package/package-lock.json" "$dir/package-lock.json"

          edit "$dir/cf.mod.nix" "s|version = \"[^\"]+\"|version = \"$version\"|"
          edit "$dir/cf.mod.nix" "/fetchurl/,/\};/s|hash = \"[^\"]+\"|hash = \"$(prefetch_url "https://registry.npmjs.org/cf/-/cf-$version.tgz")\"|"
          edit "$dir/cf.mod.nix" "s|npmDepsHash = \"[^\"]+\"|npmDepsHash = \"$(prefetch-npm-deps "$dir/package-lock.json")\"|"
          echo "cf $version"
        }

        targets=("$@")
        if [ ''${#targets[@]} -eq 0 ]; then
          targets=(inputs moshi windows-10-theme cf voxl opencode-telegram-bot)
        fi

        for target in "''${targets[@]}"; do
          case "$target" in
            inputs) update_inputs ;;
            moshi) update_moshi ;;
            windows-10-theme) update_windows_10_theme ;;
            cf) update_cf ;;
            voxl) update_voxl ;;
            opencode-telegram-bot) update_opencode_telegram_bot ;;
            *)
              echo "Unknown target: $target" >&2
              exit 1
              ;;
          esac
        done

        echo "Done. Review with 'git diff', then run 'nix flake check path:\$PWD'."
      '';
    };
  in {
    apps.update = {
      type = "app";
      program = "${update}/bin/update";
      meta.description = "Update flake inputs and hand-pinned package versions";
    };
  };
}
