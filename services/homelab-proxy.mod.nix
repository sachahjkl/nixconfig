_: {
  flake.nixosModules.homelabProxy = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit
      (lib)
      concatLines
      escapeShellArg
      listToAttrs
      mapAttrsToList
      mkEnableOption
      mkIf
      mkMerge
      mkOption
      types
      ;

    cfg = config.homelab.proxy;

    sanitize = value:
      builtins.replaceStrings ["." "-" "/"] ["_" "_" "_"] value;

    hostEntries = mapAttrsToList (domain: hostCfg: hostCfg // {inherit domain;}) cfg.hosts;
    dockerHosts = builtins.filter (hostCfg: hostCfg.dockerContainer != null) hostEntries;
    dockerSpec = builtins.listToAttrs (map
      (hostCfg: {
        name = hostCfg.domain;
        value = {
          container = hostCfg.dockerContainer;
          port = hostCfg.dockerPort;
          upstreamName = "docker_${sanitize hostCfg.domain}";
        };
      })
      dockerHosts);
    dockerSpecFile = pkgs.writeText "homelab-proxy-docker-hosts.json" (builtins.toJSON dockerSpec);

    renderHost = domain: hostCfg: let
      proxyPass =
        if hostCfg.dockerContainer != null
        then "${hostCfg.scheme}://docker_${sanitize domain}"
        else "${hostCfg.scheme}://${hostCfg.upstreamHost}:${toString hostCfg.upstreamPort}";
    in {
      name = domain;
      value = {
        inherit (hostCfg) enableACME;
        inherit (hostCfg) forceSSL;
        serverAliases = hostCfg.aliases;
        inherit (hostCfg) basicAuthFile;
        # NixOS already emits `http2 on;` for SSL vhosts; adding it again is a
        # duplicate and breaks nginx config validation.
        extraConfig = "";
        locations."/" = {
          inherit proxyPass;
          proxyWebsockets = hostCfg.websockets;
        };
      };
    };
  in {
    options.homelab.proxy = {
      enable = mkEnableOption "nginx + ACME reverse proxy for the homelab";

      acmeEmail = mkOption {
        type = types.str;
        default = "sacha@sacha.house";
        description = "Contact email used for ACME registrations.";
      };

      defaultDomainRedirect = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional domain used by the catch-all vhost redirect.";
      };

      dns = {
        enable = mkOption {
          type = types.bool;
          default = false;
        };

        defaultType = mkOption {
          type = types.enum ["A" "CNAME"];
          default = "CNAME";
        };

        defaultTarget = mkOption {
          type = types.str;
          default = "homelab.sacha.house";
        };

        defaultValue = mkOption {
          type = types.nullOr types.str;
          default = null;
        };

        defaultProxied = mkOption {
          type = types.bool;
          default = true;
        };

        defaultTTL = mkOption {
          type = types.int;
          default = 1;
        };

        zoneNames = mkOption {
          type = types.listOf types.str;
          default = [];
        };

        managedComment = mkOption {
          type = types.str;
          default = "managed-by=nixconfig.cloudflare-dns";
        };

        tokenPath = mkOption {
          type = types.str;
          default = "/run/secrets/cloudflare-api-key";
        };
      };

      hosts = mkOption {
        type = types.attrsOf (types.submodule (_: {
          options = {
            aliases = mkOption {
              type = types.listOf types.str;
              default = [];
            };

            scheme = mkOption {
              type = types.enum ["http" "https"];
              default = "http";
            };

            upstreamHost = mkOption {
              type = types.nullOr types.str;
              default = null;
            };

            upstreamPort = mkOption {
              type = types.nullOr types.port;
              default = null;
            };

            dockerContainer = mkOption {
              type = types.nullOr types.str;
              default = null;
            };

            dockerPort = mkOption {
              type = types.nullOr types.port;
              default = null;
            };

            enableACME = mkOption {
              type = types.bool;
              default = true;
            };

            forceSSL = mkOption {
              type = types.bool;
              default = true;
            };

            websockets = mkOption {
              type = types.bool;
              default = false;
            };

            http2 = mkOption {
              type = types.bool;
              default = true;
            };

            basicAuthFile = mkOption {
              type = types.nullOr types.str;
              default = null;
            };

            dns = {
              enable = mkOption {
                type = types.bool;
                default = true;
              };

              type = mkOption {
                type = types.nullOr (types.enum ["A" "CNAME"]);
                default = null;
              };

              target = mkOption {
                type = types.nullOr types.str;
                default = null;
              };

              value = mkOption {
                type = types.nullOr types.str;
                default = null;
              };

              proxied = mkOption {
                type = types.nullOr types.bool;
                default = null;
              };

              ttl = mkOption {
                type = types.nullOr types.int;
                default = null;
              };
            };
          };
        }));
        default = {};
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        persist.system.directories = [
          "/var/lib/acme"
        ];

        assertions =
          map
          (hostCfg: {
            assertion =
              (hostCfg.dockerContainer != null && hostCfg.dockerPort != null && hostCfg.upstreamHost == null && hostCfg.upstreamPort == null)
              || (hostCfg.dockerContainer == null && hostCfg.dockerPort == null && hostCfg.upstreamHost != null && hostCfg.upstreamPort != null);
            message = "Each homelab.proxy.hosts entry must define either upstreamHost+upstreamPort or dockerContainer+dockerPort.";
          })
          hostEntries;

        security.acme = {
          acceptTerms = true;
          defaults = {
            email = cfg.acmeEmail;
          };
        };

        services.nginx = {
          enable = true;
          recommendedGzipSettings = true;
          recommendedOptimisation = true;
          recommendedProxySettings = true;
          recommendedTlsSettings = true;
          commonHttpConfig = concatLines [
            "map $http_upgrade $connection_upgrade {"
            "  default upgrade;"
            "  '' close;"
            "}"
            "include /run/homelab-proxy/docker-upstreams.conf;"
          ];
          virtualHosts =
            (listToAttrs (mapAttrsToList renderHost cfg.hosts))
            // lib.optionalAttrs (cfg.defaultDomainRedirect != null) {
              "_" = {
                default = true;
                locations."/".return = "301 https://${cfg.defaultDomainRedirect}$request_uri";
              };
            };
        };

        networking.firewall.allowedTCPPorts = [80 443];

        systemd.tmpfiles.rules = [
          "d /run/homelab-proxy 0755 root root -"
          "f /run/homelab-proxy/docker-upstreams.conf 0644 root root -"
        ];
      }

      (mkIf (dockerHosts != []) {
        # NixOS nginx runs directly on the host, while the services it proxies
        # to live inside Docker networks and intentionally do not publish ports
        # on the host.  This service inspects each referenced Docker container,
        # extracts its IP address from the shared `services` network, and emits
        # nginx `upstream` blocks so the host-based nginx can reach containers by
        # their bridge-network IPs without needing any port bindings.
        systemd.services.homelab-proxy-refresh-docker-upstreams = {
          description = "Refresh nginx upstreams for docker-backed homelab services";
          wants = ["docker.service" "network-online.target"];
          after = ["docker.service" "network-online.target"];
          before = ["nginx.service"];
          wantedBy = ["multi-user.target"];
          path = with pkgs; [bash coreutils docker gnugrep gnused python3 systemd];
          serviceConfig = {
            Type = "oneshot";
          };
          script = ''
            set -euo pipefail
            mkdir -p /run/homelab-proxy
            export SPEC_FILE=${escapeShellArg dockerSpecFile}
            export OUT_FILE=/run/homelab-proxy/docker-upstreams.conf
            export TMP_FILE=/run/homelab-proxy/docker-upstreams.conf.tmp

            python3 - <<'PY'
            import json
            import os
            import subprocess

            spec_path = os.environ["SPEC_FILE"]
            out_path = os.environ["OUT_FILE"]
            tmp_path = os.environ["TMP_FILE"]

            with open(spec_path, "r", encoding="utf-8") as fh:
                spec = json.load(fh)

            lines = ["# generated by homelab-proxy-refresh-docker-upstreams"]
            for domain, entry in spec.items():
                container = entry["container"]
                port = entry["port"]
                upstream_name = entry["upstreamName"]
                target = "127.0.0.1"
                try:
                    inspect = subprocess.check_output(["docker", "inspect", container], text=True)
                    data = json.loads(inspect)[0]
                    networks = data.get("NetworkSettings", {}).get("Networks", {})
                    for network_name in ("services", *networks.keys()):
                        network = networks.get(network_name)
                        if network and network.get("IPAddress"):
                            target = network["IPAddress"]
                            break
                except Exception:
                    target = "127.0.0.1"
                    port = 9

                lines.append(f"upstream {upstream_name} {{")
                lines.append(f"  server {target}:{port};")
                lines.append("  keepalive 32;")
                lines.append("}")

            content = "\n".join(lines) + "\n"
            with open(tmp_path, "w", encoding="utf-8") as fh:
                fh.write(content)
            os.replace(tmp_path, out_path)
            PY

            if systemctl is-active --quiet nginx.service; then
              # Use --no-block to avoid a deadlock: this service is ordered
              # Before=nginx.service, so a blocking reload would wait for nginx
              # to finish starting while nginx waits for this service to finish.
              systemctl reload --no-block nginx.service
            fi
          '';
        };

        systemd.timers.homelab-proxy-refresh-docker-upstreams = {
          wantedBy = ["timers.target"];
          timerConfig = {
            OnBootSec = "1min";
            OnUnitActiveSec = "2min";
            Unit = "homelab-proxy-refresh-docker-upstreams.service";
          };
        };
      })
    ]);
  };
}
