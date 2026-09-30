{self, ...}: {
  perSystem = {pkgs, ...}: {
    checks.openbao-maintenance =
      pkgs.runCommand "openbao-maintenance-tests" {
        nativeBuildInputs = [pkgs.python3];
      } ''
        export PYTHONDONTWRITEBYTECODE=1
        export BAO_BIN=${pkgs.lib.getExe pkgs.openbao}
        python -m unittest discover -s ${./.} -p 'test_openbao_maintenance.py'
        touch "$out"
      '';
  };

  flake.nixosModules.openbaoPlatform = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.openbaoPlatform;
    certificate = config.security.acme.certs.${cfg.domain}.directory;
    maintenance = pkgs.writeText "openbao-maintenance.py" (builtins.readFile ./openbao_maintenance.py);
  in {
    imports = [self.nixosModules.sops];

    options.services.openbaoPlatform = {
      enable = lib.mkEnableOption "private OpenBao secret storage";
      domain = lib.mkOption {
        type = lib.types.str;
        description = "DNS name resolving to the private OpenBao address.";
      };
      address = lib.mkOption {
        type = lib.types.str;
        description = "Tailscale address of the OpenBao listener.";
      };
      interface = lib.mkOption {
        type = lib.types.str;
        description = "Private interface accepting OpenBao traffic.";
      };
      dataDir = lib.mkOption {
        type = lib.types.str;
        description = "Persistent directory containing Raft data and audit logs.";
      };
      secretDir = lib.mkOption {
        type = lib.types.str;
        description = "Root-only persistent directory containing maintenance credentials.";
      };
      snapshotDir = lib.mkOption {
        type = lib.types.str;
        description = "Persistent directory containing the latest Raft snapshot.";
      };
      acmeEmail = lib.mkOption {
        type = lib.types.str;
        description = "Contact email for the TLS certificate.";
      };
      sopsFile = lib.mkOption {
        type = lib.types.path;
        description = "SOPS file containing the Cloudflare DNS token.";
      };
    };

    config = lib.mkIf cfg.enable {
      users.groups.openbao = {};
      users.users.openbao = {
        isSystemUser = true;
        group = "openbao";
      };

      sops.secrets."openbao/cloudflare-dns" = {
        inherit (cfg) sopsFile;
        key = "cloudflare/dns";
      };
      security.acme = {
        acceptTerms = true;
        certs.${cfg.domain} = {
          email = cfg.acmeEmail;
          dnsProvider = "cloudflare";
          credentialFiles.CF_DNS_API_TOKEN_FILE = config.sops.secrets."openbao/cloudflare-dns".path;
          group = "openbao";
          reloadServices = ["openbao.service"];
        };
      };

      services.openbao = {
        enable = true;
        settings = {
          ui = true;
          disable_mlock = true;
          audit = [
            {
              type = "file";
              path = "host";
              options.file_path = "${cfg.dataDir}/audit.json";
            }
          ];
          api_addr = "https://${cfg.domain}";
          cluster_addr = "https://127.0.0.1:8201";
          storage.raft = {
            path = "${cfg.dataDir}/raft";
            node_id = config.networking.hostName;
          };
          listener = {
            private = {
              type = "tcp";
              address = "${cfg.address}:443";
              cluster_address = "127.0.0.1:8201";
              tls_cert_file = "${certificate}/fullchain.pem";
              tls_key_file = "${certificate}/key.pem";
              tls_min_version = "tls12";
            };
            maintenance = {
              type = "tcp";
              address = "127.0.0.1:8202";
              cluster_address = "127.0.0.1:8203";
              tls_disable = true;
            };
          };
        };
      };

      networking.firewall.interfaces.${cfg.interface}.allowedTCPPorts = [443];
      services.logrotate.settings.openbao-audit = {
        files = ["${cfg.dataDir}/audit.json"];
        frequency = "weekly";
        rotate = 8;
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
        create = "0600 openbao openbao";
        postrotate = "${pkgs.systemd}/bin/systemctl kill --kill-whom=main --signal=HUP openbao.service";
      };
      systemd = {
        tmpfiles.rules = [
          "d ${cfg.dataDir} 0700 openbao openbao -"
          "d ${cfg.dataDir}/raft 0700 openbao openbao -"
          "d ${cfg.secretDir} 0700 root root -"
          "d ${cfg.snapshotDir} 0700 root root -"
        ];

        services = {
          openbao = {
            wants = ["network-online.target"];
            requires = ["acme-${cfg.domain}.service"];
            after = ["network-online.target" "acme-${cfg.domain}.service"];
            unitConfig.RequiresMountsFor = [cfg.dataDir];
            serviceConfig = {
              DynamicUser = lib.mkForce false;
              CapabilityBoundingSet = lib.mkForce ["CAP_NET_BIND_SERVICE"];
              AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
              PrivateUsers = lib.mkForce false;
              ProtectSystem = "strict";
              ReadWritePaths = [cfg.dataDir];
            };
          };

          openbao-unseal = {
            description = "Unseal OpenBao with the local host key";
            after = ["openbao.service"];
            unitConfig.ConditionPathExists = "${cfg.secretDir}/unseal-key";
            serviceConfig = {
              Type = "oneshot";
              LoadCredential = "unseal-key:${cfg.secretDir}/unseal-key";
              ExecStart = "${lib.getExe pkgs.python3} ${maintenance} unseal";
              User = "root";
              UMask = "0077";
              ProtectSystem = "strict";
              ProtectHome = true;
              PrivateTmp = true;
              NoNewPrivileges = true;
            };
          };

          openbao-snapshot = {
            description = "Save a consistent OpenBao Raft snapshot";
            after = ["openbao.service" "openbao-unseal.service"];
            unitConfig.ConditionPathExists = "${cfg.secretDir}/snapshot-approle.json";
            serviceConfig = {
              Type = "oneshot";
              LoadCredential = "snapshot-approle.json:${cfg.secretDir}/snapshot-approle.json";
              ExecStart = "${lib.getExe pkgs.python3} ${maintenance} snapshot ${lib.escapeShellArg cfg.snapshotDir}";
              User = "root";
              UMask = "0077";
              ProtectSystem = "strict";
              ReadWritePaths = [cfg.snapshotDir];
              ProtectHome = true;
              PrivateTmp = true;
              NoNewPrivileges = true;
            };
          };
        };

        timers = {
          openbao-unseal = {
            wantedBy = ["timers.target"];
            timerConfig = {
              OnBootSec = "15s";
              OnUnitActiveSec = "30s";
            };
          };
          openbao-snapshot = {
            wantedBy = ["timers.target"];
            timerConfig = {
              OnCalendar = "03:30";
              Persistent = true;
            };
          };
        };
      };
    };
  };
}
