_: {
  perSystem = {
    lib,
    pkgs,
    self',
    ...
  }: let
    gh = pkgs.writeShellScriptBin "gh" ''
      if [ -r /run/secrets/github-far-from-home-pat ]; then
        export GH_TOKEN="$(cat /run/secrets/github-far-from-home-pat)"
        export GITHUB_TOKEN="$GH_TOKEN"
      fi

      exec ${lib.getExe pkgs.gh} "$@"
    '';
    homelabAppCreate = pkgs.writeShellApplication {
      name = "homelab-app-create";
      runtimeInputs = with pkgs; [coreutils gnugrep jq] ++ [gh];
      text = ''
        set -euo pipefail

        usage() {
          cat <<'EOF'
        Usage: homelab-app-create \
          --repository REPOSITORY \
          --application APPLICATION \
          --production-domain DOMAIN \
          --staging-domain DOMAIN \
          [--volume-path PATH] \
          [--private]

        Create and configure a repository from the homelab application template.
        EOF
        }

        repository=""
        application=""
        production_domain=""
        staging_domain=""
        volume_path=""
        visibility="public"

        while [ "$#" -gt 0 ]; do
          case "$1" in
            --repository)
              repository="$2"
              shift 2
              ;;
            --application)
              application="$2"
              shift 2
              ;;
            --production-domain)
              production_domain="$2"
              shift 2
              ;;
            --staging-domain)
              staging_domain="$2"
              shift 2
              ;;
            --volume-path)
              volume_path="$2"
              shift 2
              ;;
            --private)
              visibility="private"
              shift
              ;;
            --help|-h)
              usage
              exit 0
              ;;
            *)
              printf 'Unknown argument: %s\n' "$1" >&2
              usage >&2
              exit 1
              ;;
          esac
        done

        if [ -z "$repository" ] || [ -z "$application" ] || [ -z "$production_domain" ] || [ -z "$staging_domain" ]; then
          usage >&2
          exit 1
        fi

        name_pattern='^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$'
        domain_pattern='^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$'
        if ! grep -Eq "$name_pattern" <<<"$application"; then
          printf 'Invalid application name: %s\n' "$application" >&2
          exit 1
        fi

        trusted_domain() {
          local domain="$1"
          grep -Eq "$domain_pattern" <<<"$domain" \
            && grep -Eq '^(sacha\.house|homelab\.sacha\.house|froment\.software|.+\.(sacha\.house|homelab\.sacha\.house|froment\.software))$' <<<"$domain"
        }

        if ! trusted_domain "$production_domain"; then
          printf 'Untrusted production domain: %s\n' "$production_domain" >&2
          exit 1
        fi
        if ! trusted_domain "$staging_domain"; then
          printf 'Untrusted staging domain: %s\n' "$staging_domain" >&2
          exit 1
        fi
        if [ "$production_domain" = "$staging_domain" ]; then
          printf 'Staging and production domains must differ.\n' >&2
          exit 1
        fi
        if [ -n "$volume_path" ]; then
          if ! grep -Eq '^/[A-Za-z0-9._/-]+$' <<<"$volume_path"; then
            printf 'Invalid volume path: %s\n' "$volume_path" >&2
            exit 1
          fi
          case "$volume_path" in
            /|*..*|//*|*/)
              printf 'Invalid volume path: %s\n' "$volume_path" >&2
              exit 1
              ;;
            /*) ;;
            *)
              printf 'The volume path must be absolute: %s\n' "$volume_path" >&2
              exit 1
              ;;
          esac
        fi

        owner="$(gh api user --jq .login)"
        user_id="$(gh api user --jq .id)"
        full_repository="$owner/$repository"
        if gh repo view "$full_repository" >/dev/null 2>&1; then
          printf 'Repository already exists: %s\n' "$full_repository" >&2
          exit 1
        fi

        private=false
        if [ "$visibility" = "private" ]; then
          private=true
        fi
        jq -cn \
          --arg owner "$owner" \
          --arg name "$repository" \
          --argjson private "$private" \
          '{owner:$owner,name:$name,private:$private,include_all_branches:false}' \
          | gh api --method POST \
              repos/sachahjkl/homelab-application-template/generate \
              --input - >/dev/null

        for _ in $(seq 1 30); do
          if gh api "repos/$full_repository/contents/application.yaml" >/dev/null 2>&1; then
            break
          fi
          sleep 2
        done

        for environment in staging production; do
          environment_config='{"deployment_branch_policy":{"protected_branches":false,"custom_branch_policies":true}}'
          if [ "$environment" = production ]; then
            environment_config="$(
              jq -cn --argjson id "$user_id" \
                '{prevent_self_review:false,reviewers:[{type:"User",id:$id}],deployment_branch_policy:{protected_branches:false,custom_branch_policies:true}}'
            )"
          fi
          gh api --method PUT \
            "repos/$full_repository/environments/$environment" \
            --input - <<<"$environment_config" >/dev/null
          gh api --method POST \
            "repos/$full_repository/environments/$environment/deployment-branch-policies" \
            -f name=master -f type=branch >/dev/null
        done

        current_file="$(gh api "repos/$full_repository/contents/application.yaml")"
        current_sha="$(jq -r .sha <<<"$current_file")"
        manifest="$(mktemp)"
        trap 'rm -f "$manifest"' EXIT
        cat >"$manifest" <<EOF
        application:
          name: $application
          port: 8080
          healthPath: /health

        domain:
          production: $production_domain
          staging: $staging_domain
        EOF
        if [ -n "$volume_path" ]; then
          cat >>"$manifest" <<EOF

        volume:
          mountPath: $volume_path
        EOF
        fi
        manifest_content="$(base64 -w0 <"$manifest")"
        jq -cn \
          --arg message "Configure $application" \
          --arg content "$manifest_content" \
          --arg sha "$current_sha" \
          '{message:$message,content:$content,sha:$sha,branch:"master"}' \
          | gh api --method PUT \
              "repos/$full_repository/contents/application.yaml" \
              --input - >/dev/null

        jq -cn '{
          required_status_checks:{strict:true,contexts:["check"]},
          enforce_admins:true,
          required_pull_request_reviews:{dismiss_stale_reviews:true,required_approving_review_count:0},
          restrictions:null,
          required_conversation_resolution:true,
          allow_force_pushes:false,
          allow_deletions:false
        }' | gh api --method PUT \
          "repos/$full_repository/branches/master/protection" \
          --input - >/dev/null

        printf 'Created https://github.com/%s\n' "$full_repository"
        printf 'Staging will deploy to https://%s\n' "$staging_domain"
        printf 'Production requires approval at https://github.com/%s/actions/workflows/deploy-production.yml\n' "$full_repository"
      '';
    };
  in {
    packages.homelabAppCreate = homelabAppCreate;
    apps.homelabAppCreate = {
      type = "app";
      program = lib.getExe self'.packages.homelabAppCreate;
    };
  };
}
