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
    applicationCreate = pkgs.writeShellApplication {
      name = "application-create";
      runtimeInputs = with pkgs; [coreutils gitMinimal gnugrep jq nix] ++ [gh];
      text = ''
        set -euo pipefail

        usage() {
          cat <<'EOF'
        Usage: application-create \
          --repository REPOSITORY \
          --application APPLICATION \
          --environment NAME=DOMAIN \
          --deployment-environment NAME \
          [--environment NAME=DOMAIN] ... \
          [--approval-environment NAME] ... \
          [--no-index-environment NAME] ... \
          [--volume-path PATH] \
          [--private]

        Create and configure a repository from the application template.
        EOF
        }

        repository=""
        application=""
        declare -a environment_names=()
        declare -a approval_environments=()
        declare -a no_index_environments=()
        declare -A domains=()
        deployment_environment=""
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
            --environment)
              environment_name="''${2%%=*}"
              domain="''${2#*=}"
              if [ "$environment_name" = "$2" ] || [ -z "$environment_name" ] || [ -z "$domain" ]; then
                printf 'Invalid environment: %s\n' "$2" >&2
                exit 1
              fi
              if [ -n "''${domains[$environment_name]+set}" ]; then
                printf 'Duplicate environment: %s\n' "$environment_name" >&2
                exit 1
              fi
              environment_names+=("$environment_name")
              domains["$environment_name"]="$domain"
              shift 2
              ;;
            --approval-environment)
              approval_environments+=("$2")
              shift 2
              ;;
            --deployment-environment)
              deployment_environment="$2"
              shift 2
              ;;
            --no-index-environment)
              no_index_environments+=("$2")
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

        if [ -z "$repository" ] || [ -z "$application" ] || [ -z "$deployment_environment" ] \
          || [ "''${#environment_names[@]}" -eq 0 ]; then
          usage >&2
          exit 1
        fi

        name_pattern='^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$'
        if ! grep -Eq "$name_pattern" <<<"$application"; then
          printf 'Invalid application name: %s\n' "$application" >&2
          exit 1
        fi

        contains() {
          local expected="$1"
          shift
          local value
          for value in "$@"; do
            if [ "$value" = "$expected" ]; then
              return 0
            fi
          done
          return 1
        }

        for environment_name in "''${environment_names[@]}"; do
          if ! grep -Eq "$name_pattern" <<<"$environment_name"; then
            printf 'Invalid environment name: %s\n' "$environment_name" >&2
            exit 1
          fi
        done
        for environment_name in "''${approval_environments[@]}" "''${no_index_environments[@]}"; do
          if [ -n "$environment_name" ] && [ -z "''${domains[$environment_name]+set}" ]; then
            printf 'Environment is not declared: %s\n' "$environment_name" >&2
            exit 1
          fi
        done
        if [ -z "''${domains[$deployment_environment]+set}" ]; then
          printf 'Deployment environment is not declared: %s\n' "$deployment_environment" >&2
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
        jq -cn --arg name "$repository" --argjson private "$private" \
          '{name:$name,private:$private}' \
          | gh api --method POST user/repos --input - >/dev/null

        checkout="$(mktemp -d)"
        trap 'rm -rf "$checkout"' EXIT
        nix flake new \
          -t github:sachahjkl/application-template/v1.1.0 \
          "$checkout"

        cat >"$checkout/.github/workflows/ci.yml" <<EOF
        name: CI

        on:
          push:
            branches: [master]
          pull_request:
            branches: [master]
          workflow_dispatch:

        jobs:
          platform:
            permissions:
              attestations: write
              contents: read
              id-token: write
              packages: write
            uses: sachahjkl/deployment-actions/.github/workflows/application-ci.yml@v4.0.0
            with:
              deployment-environment: $deployment_environment
        EOF
        rm "$checkout/.github/workflows/deploy-production.yml"
        for target_environment in "''${approval_environments[@]}"; do
          cat >"$checkout/.github/workflows/promote-$target_environment.yml" <<EOF
        name: Promote $target_environment

        on:
          workflow_dispatch:

        jobs:
          promotion:
            permissions:
              attestations: read
              contents: read
              id-token: write
              packages: read
            uses: sachahjkl/deployment-actions/.github/workflows/application-promotion.yml@v4.0.0
            with:
              source-environment: $deployment_environment
              target-environment: $target_environment
        EOF
        done

        for environment in "''${environment_names[@]}"; do
          environment_config='{"deployment_branch_policy":{"protected_branches":false,"custom_branch_policies":true}}'
          if contains "$environment" "''${approval_environments[@]}"; then
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

        cat >"$checkout/application.yaml" <<EOF
        application:
          name: $application
          port: 8080
          healthPath: /health

        environments:
        EOF
        for environment_name in "''${environment_names[@]}"; do
          {
            printf '  %s:\n' "$environment_name"
            printf '    domain: %s\n' "$(jq -Rn --arg value "''${domains[$environment_name]}" '$value')"
            if contains "$environment_name" "''${no_index_environments[@]}"; then
              printf '    noIndex: true\n'
            fi
          } >>"$checkout/application.yaml"
        done
        cat >>"$checkout/application.yaml" <<EOF

        resources:
          cpu: 200
          memory: 256
        EOF
        if [ -n "$volume_path" ]; then
          cat >>"$checkout/application.yaml" <<EOF

        volume:
          mountPath: $volume_path
        EOF
        fi

        git -C "$checkout" init --initial-branch master
        git -C "$checkout" add .
        git -C "$checkout" commit -S -m "Create $application"
        git -C "$checkout" remote add origin "git@github.com:$full_repository.git"
        git -C "$checkout" push --set-upstream origin master

        jq -cn '{
          required_status_checks:{strict:true,contexts:["platform / check"]},
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
        for environment_name in "''${environment_names[@]}"; do
          printf '%s uses https://%s\n' "$environment_name" "''${domains[$environment_name]}"
        done
      '';
    };
  in {
    packages.applicationCreate = applicationCreate;
    apps.applicationCreate = {
      type = "app";
      program = lib.getExe self'.packages.applicationCreate;
    };
  };
}
