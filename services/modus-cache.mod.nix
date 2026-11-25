{inputs, ...}: {
  flake.nixosModules.modusCache = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.modusCache;
    modusPkg = inputs.modus.packages.${pkgs.stdenv.hostPlatform.system}.modustool;
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
        description = "Address on which the object cache TCP and UDP (QUIC) server listens.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 5010;
        description = "TCP and UDP (QUIC) port for the framed MOCQ/MOCR object cache protocol.";
      };

      statusPort = lib.mkOption {
        type = lib.types.port;
        default = 5011;
        description = "Loopback HTTP port where cache-serve itself serves the page of the public object cache and status.json.";
      };

      endpoint = lib.mkOption {
        type = lib.types.str;
        default = "cache.modus.systems:5010";
        description = "Public host:port endpoint that the page names.";
      };

      siteAddress = lib.mkOption {
        type = lib.types.str;
        default = "https://modus.systems";
        description = "Address of the site of modus, whose style sheet, fonts and mark the page uses.";
      };

      authorizedKeyFiles = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [];
        description = "Optional Ed25519 public key files authorized to upload objects and realisations.";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Open the object cache TCP and UDP (QUIC) port in the firewall.";
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
      networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [cfg.port];

      systemd = {
        tmpfiles.rules = [
          "d ${cfg.dataDir} 0750 modus-cache modus-cache -"
          "Z ${cfg.dataDir} - modus-cache modus-cache -"
        ];

        # cache-serve serves the page of the public object cache itself, so the
        # counts come from the server and no scan of the store runs.
        services.modus-cache = {
          description = "Modus content-addressed object cache server and its page";
          wants = ["network-online.target"];
          after = ["network-online.target"];
          wantedBy = ["multi-user.target"];
          unitConfig.RequiresMountsFor = [cfg.dataDir];
          serviceConfig = {
            User = "modus-cache";
            Group = "modus-cache";
            ExecStart = "${modusPkg}/bin/modustool cache-serve --dir ${cfg.dataDir} --listen ${cfg.listenAddress}:${toString cfg.port} --status-listen 127.0.0.1:${toString cfg.statusPort} --endpoint ${cfg.endpoint} --site ${cfg.siteAddress}${authorizedKeyArgs}";
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
            # The page runs on its own thread, and the thread library of Odin
            # sets the scheduling of each new thread: sched_setscheduler, which
            # ~@resources forbids, so it is allowed again by name.
            SystemCallFilter = ["@system-service" "~@privileged" "~@resources" "sched_setscheduler"];
            UMask = "0027";
          };
        };
      };
    };
  };
}
