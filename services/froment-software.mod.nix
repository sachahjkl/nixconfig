{self, ...}: {
  flake.nixosModules.fromentSoftware = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.homelab.services.fromentSoftware;
    serviceRoot = "${config.homelab.dataRoot}/Services/froment-software";
    ageKey = "${config.homeDirectory}/.config/sops/age/keys.txt";
    imagePattern = "^ghcr\\.io/sachahjkl/froment\\.software@sha256:[0-9a-f]{64}$";
    deploy = pkgs.writeShellApplication {
      name = "froment-software-deploy";
      runtimeInputs = with pkgs; [
        coreutils
        curl
        docker
        gnugrep
        sqlite
        systemd
        util-linux
      ];
      text = ''
        set -euo pipefail

        if [[ $# -ne 2 ]]; then
          echo "Usage: froment-software-deploy ENVIRONMENT IMAGE_DIGEST" >&2
          exit 64
        fi

        environment=$1
        image=$2
        if [[ ! $image =~ ${imagePattern} ]]; then
          echo "The image must use the Froment GHCR repository and an exact sha256 digest." >&2
          exit 64
        fi

        case "$environment" in
          staging)
            container=froment-software-staging
            origin=https://staging.froment.software
            profile=staging
            site_phase=live
            ;;
          production)
            container=froment-software
            origin=https://froment.software
            profile=production
            site_phase=construction
            ;;
          *)
            echo "Unsupported environment: $environment" >&2
            exit 64
            ;;
        esac

        exec 9>/run/lock/froment-software-deploy.lock
        flock 9

        environment_root=${serviceRoot}/$environment
        data_root=$environment_root/data
        backup_root=$environment_root/backups
        database=$data_root/froment.sqlite
        if [[ $environment == production ]]; then
          staged_image=$(cat ${serviceRoot}/staging/deployed-image 2>/dev/null || true)
          if [[ $staged_image != "$image" ]]; then
            echo "Production accepts only the image currently deployed to staging." >&2
            exit 65
          fi
        fi
        mkdir -p "$data_root" "$backup_root"
        chown 1000:100 "$data_root"
        chmod 0750 "$data_root" "$backup_root"

        docker pull "$image"

        old_image=
        source_database=$database
        if docker container inspect "$container" >/dev/null 2>&1; then
          old_image=$(docker container inspect --format '{{.Image}}' "$container")
          mounted_source=$(docker container inspect --format '{{range .Mounts}}{{if eq .Destination "/var/lib/froment-software"}}{{.Source}}{{end}}{{end}}' "$container")
          if [[ -n $mounted_source ]]; then
            source_database=$mounted_source/froment.sqlite
          fi
          docker stop --time 30 "$container"
          docker rm "$container"
        fi

        backup=
        if [[ -s $source_database ]]; then
          timestamp=$(date --utc +%Y%m%dT%H%M%SZ)
          backup=$backup_root/pre-deploy-$timestamp.sqlite
          sqlite3 "$source_database" ".backup '$backup.tmp'"
          [[ $(sqlite3 "$backup.tmp" 'pragma integrity_check;') == ok ]]
          mv "$backup.tmp" "$backup"
          chmod 0600 "$backup"
          if [[ $source_database != "$database" ]]; then
            cp "$backup" "$database"
            chown 1000:100 "$database"
            chmod 0600 "$database"
          fi
        fi

        run_container() {
          local selected_image=$1
          docker run --detach \
            --name "$container" \
            --network services \
            --restart unless-stopped \
            --label com.centurylinklabs.watchtower.enable=false \
            --env APP_ENV="$environment" \
            --env SITE_PHASE="$site_phase" \
            --env PUBLIC_ORIGIN="$origin" \
            --env SECRETSPEC_PROFILE="$profile" \
            --env SOPS_AGE_KEY_FILE=/run/secrets/sops-age-key \
            --env OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318 \
            --env OTEL_LOGS_EXPORTER=otlp \
            --env OTEL_TRACES_EXPORTER=otlp \
            --volume "${ageKey}:/run/secrets/sops-age-key:ro" \
            --volume "$data_root:/var/lib/froment-software" \
            "$selected_image"
        }

        run_container "$image"

        healthy=false
        for _attempt in $(seq 1 60); do
          if ! docker container inspect "$container" >/dev/null 2>&1; then
            break
          fi
          container_ip=$(docker container inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")
          if [[ -n $container_ip ]] && curl --fail --silent --show-error "http://$container_ip:3000/api/health" | grep --quiet '"status":"ok"'; then
            healthy=true
            break
          fi
          sleep 1
        done

        if [[ $healthy != true ]]; then
          docker logs "$container" >&2 || true
          docker rm --force "$container" >/dev/null 2>&1 || true
          if [[ -n $backup ]]; then
            rm -f "$database" "$database-shm" "$database-wal"
            cp "$backup" "$database"
            chown 1000:100 "$database"
            chmod 0600 "$database"
          fi
          if [[ -n $old_image ]]; then
            run_container "$old_image" >/dev/null
          fi
          systemctl start homelab-proxy-refresh-docker-upstreams.service
          echo "Deployment failed. The previous image and database were restored." >&2
          exit 1
        fi

        printf '%s\n' "$image" >"$environment_root/deployed-image"
        chmod 0640 "$environment_root/deployed-image"
        find "$backup_root" -maxdepth 1 -type f -name 'pre-deploy-*.sqlite' -printf '%T@ %p\n' \
          | sort --numeric-sort --reverse \
          | tail --lines=+11 \
          | cut --delimiter=' ' --fields=2- \
          | xargs --no-run-if-empty rm --
        systemctl start homelab-proxy-refresh-docker-upstreams.service
        echo "Deployed $image to $environment."
      '';
    };
  in {
    imports = [self.nixosModules.sops];

    options.homelab.services.fromentSoftware.enable =
      lib.mkEnableOption "digest-pinned Froment Software deployments";

    config = lib.mkIf cfg.enable {
      sops.secrets."froment/staging-basic-auth" = {
        sopsFile = builtins.path {
          path = self + /secrets/homelab.yaml;
          name = "homelab-secrets.yaml";
        };
        owner = "nginx";
        group = "nginx";
        mode = "0400";
      };

      systemd.tmpfiles.rules = [
        "d ${serviceRoot} 0750 root users -"
        "d ${serviceRoot}/production 0750 root users -"
        "d ${serviceRoot}/production/data 0750 1000 users -"
        "d ${serviceRoot}/production/backups 0750 root users -"
        "d ${serviceRoot}/staging 0750 root users -"
        "d ${serviceRoot}/staging/data 0750 1000 users -"
        "d ${serviceRoot}/staging/backups 0750 root users -"
      ];

      environment.systemPackages = [deploy];
      security.sudo.extraRules = [
        {
          users = ["github-runner"];
          commands = [
            {
              command = "${deploy}/bin/froment-software-deploy";
              options = ["NOPASSWD"];
            }
          ];
        }
      ];
    };
  };
}
