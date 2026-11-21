{inputs, ...}: {
  flake.nixosModules.modusCache = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.modusCache;
    modusPkg = inputs.modus.packages.${pkgs.stdenv.hostPlatform.system}.modustool;
    dashboardPage = builtins.path {
      path = ./modus-cache/dashboard.html;
      name = "modus-cache-dashboard.html";
    };
    dashboardFiles = pkgs.runCommand "modus-cache-dashboard" {} ''
      install -Dm444 ${dashboardPage} $out/index.html
    '';
    dashboardRoot = "/run/modus-cache-dashboard";
    authorizedKeyArgs = lib.optionalString (cfg.authorizedKeyFiles != []) (
      " " + lib.concatMapStringsSep " " (keyFile: "--authorized-key ${toString keyFile}") cfg.authorizedKeyFiles
    );
  in {
    options.services.modusCache = {
      enable = lib.mkEnableOption "modus content-addressed object cache";

      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/data/modus-cache";
        description = "Persistent directory holding content-addressed objects and signed realisations.";
      };

      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
        description = "Address on which the object cache TCP server listens.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 5010;
        description = "TCP port for the framed MOCQ/MOCR object cache protocol.";
      };

      statusPort = lib.mkOption {
        type = lib.types.port;
        default = 5011;
        description = "Loopback HTTP port for the read-only cache status page.";
      };

      endpoint = lib.mkOption {
        type = lib.types.str;
        default = "cache.modus.froment.software:5010";
        description = "Public host:port endpoint shown on the status page.";
      };

      authorizedKeyFiles = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [];
        description = "Optional Ed25519 public key files authorized to upload objects and realisations.";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Open the object cache TCP port in the firewall.";
      };
    };

    config = lib.mkIf cfg.enable {
      # Pinned like traefik, openbao, and docker-registry so dataDir ownership never drifts.
      users.groups.modus-cache.gid = 984;
      users.users.modus-cache = {
        isSystemUser = true;
        uid = 984;
        group = "modus-cache";
        description = "Modus content-addressed object cache";
      };

      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];

      systemd = {
        tmpfiles.rules = [
          "d ${cfg.dataDir} 0750 modus-cache modus-cache -"
          "Z ${cfg.dataDir} - modus-cache modus-cache -"
        ];

        services = {
          modus-cache = {
            description = "Modus content-addressed object cache server";
            wants = ["network-online.target"];
            after = ["network-online.target"];
            wantedBy = ["multi-user.target"];
            unitConfig.RequiresMountsFor = [cfg.dataDir];
            serviceConfig = {
              User = "modus-cache";
              Group = "modus-cache";
              ExecStart = "${modusPkg}/bin/modustool cache-serve --dir ${cfg.dataDir} --listen ${cfg.listenAddress}:${toString cfg.port}${authorizedKeyArgs}";
              Restart = "always";
              RestartSec = "5s";
              NoNewPrivileges = true;
              PrivateTmp = true;
              PrivateDevices = true;
              ProtectSystem = "strict";
              ProtectHome = true;
              ReadWritePaths = [cfg.dataDir];
              ProtectKernelTunables = true;
              ProtectKernelModules = true;
              ProtectControlGroups = true;
              RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
              RestrictNamespaces = true;
              RestrictRealtime = true;
              LockPersonality = true;
              MemoryDenyWriteExecute = true;
              CapabilityBoundingSet = "";
              AmbientCapabilities = "";
              SystemCallFilter = ["@system-service" "~@privileged" "~@resources"];
              UMask = "0027";
            };
          };

          modus-cache-dashboard = {
            description = "Update the modus object cache status page";
            after = ["modus-cache.service"];
            wantedBy = ["multi-user.target"];
            path = [pkgs.coreutils pkgs.findutils pkgs.jq pkgs.systemd];
            serviceConfig.Type = "oneshot";
            script = ''
              set -euo pipefail
              install -d -m 0755 ${dashboardRoot}
              ln -sfn ${dashboardFiles}/index.html ${dashboardRoot}/index.html

              data_dir=${lib.escapeShellArg cfg.dataDir}
              object_count=0
              if [ -d "$data_dir/objects" ]; then
                object_count="$(find "$data_dir/objects" -maxdepth 1 -type f | wc -l)"
              fi

              realisation_count=0
              if [ -d "$data_dir/realisations" ]; then
                realisation_count="$(find "$data_dir/realisations" -maxdepth 1 -type f | wc -l)"
              fi

              cache_bytes=0
              if [ -d "$data_dir" ]; then
                cache_bytes="$(du --bytes --summarize "$data_dir" | cut -f1)"
              fi

              df_target="$data_dir"
              if [ ! -d "$df_target" ]; then
                df_target="/"
              fi
              read -r total used available percent < <(
                df --block-size=1 --output=size,used,avail,pcent "$df_target" | tail -n 1
              )
              service_status="$(systemctl is-active modus-cache.service || true)"

              jq -n \
                --arg service "$service_status" \
                --arg endpoint ${lib.escapeShellArg cfg.endpoint} \
                --arg protocol "MOCQ/MOCR" \
                --arg usedPercent "$percent" \
                --arg updatedAt "$(date --iso-8601=seconds)" \
                --argjson objectCount "$object_count" \
                --argjson realisationCount "$realisation_count" \
                --argjson cacheBytes "$cache_bytes" \
                --argjson totalBytes "$total" \
                --argjson usedBytes "$used" \
                --argjson availableBytes "$available" \
                '{
                  $service,
                  $endpoint,
                  $protocol,
                  $objectCount,
                  $realisationCount,
                  $cacheBytes,
                  $usedPercent,
                  $updatedAt,
                  $totalBytes,
                  $usedBytes,
                  $availableBytes
                }' > ${dashboardRoot}/status.json.tmp

              chmod 0644 ${dashboardRoot}/status.json.tmp
              mv ${dashboardRoot}/status.json.tmp ${dashboardRoot}/status.json
            '';
          };

          modus-cache-dashboard-server = {
            description = "Serve the modus object cache status page to Traefik";
            requires = ["modus-cache-dashboard.service"];
            after = ["modus-cache-dashboard.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              DynamicUser = true;
              ExecStart = "${pkgs.python3}/bin/python -m http.server ${toString cfg.statusPort} --bind 127.0.0.1 --directory ${dashboardRoot}";
              Restart = "on-failure";
            };
          };
        };

        timers.modus-cache-dashboard = {
          description = "Refresh the modus object cache status page";
          wantedBy = ["timers.target"];
          timerConfig = {
            OnBootSec = "1min";
            OnUnitActiveSec = "1min";
            Unit = "modus-cache-dashboard.service";
          };
        };
      };
    };
  };
}
