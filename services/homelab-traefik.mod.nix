{self, ...}: {
  flake.nixosModules.homelabTraefik = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = lib.attrByPath ["homelab" "proxy"] {} config;
    enabled = cfg.enable or false;

    sanitize = value:
      builtins.replaceStrings ["." "-" "/"] ["_" "_" "_"] value;

    usesCloudflareDns = domain:
      builtins.any (zone: domain == zone || lib.hasSuffix ".${zone}" domain) cfg.dns.acmeZoneNames;

    routeSpec =
      lib.mapAttrs
      (domain: hostCfg: {
        inherit domain;
        inherit (hostCfg) aliases basicAuthFile dockerContainer dockerPort maxRequestBodyBytes pathRoutes robotsNoIndex scheme upstreamHost upstreamPort;
        certResolver =
          if usesCloudflareDns domain
          then "cloudflare"
          else "letsencrypt";
        serviceName = "direct-${sanitize domain}";
      })
      cfg.hosts;

    routeSpecFile = pkgs.writeText "homelab-traefik-routes.json" (builtins.toJSON {
      inherit (cfg) defaultDomainRedirect;
      hosts = routeSpec;
    });
  in {
    imports = [self.nixosModules.sops];

    config = lib.mkIf enabled {
      persist.system.directories = ["/var/lib/traefik"];

      sops.secrets."cloudflare/traefik-dns" = {
        sopsFile = self + /secrets/shared.yaml;
        key = "cloudflare/dns";
        owner = "traefik";
        group = "traefik";
        mode = "0400";
      };

      sops.templates."traefik-cloudflare.env" = {
        owner = "traefik";
        group = "traefik";
        mode = "0400";
        content = ''
          CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare/traefik-dns"}
        '';
      };

      services.traefik = {
        dynamicConfigFile = "/run/homelab-traefik/routes.yaml";
        environmentFiles = [config.sops.templates."traefik-cloudflare.env".path];
        staticConfigOptions = {
          entryPoints = {
            web = {
              address = "${cfg.address}:80";
              http.redirections.entryPoint = {
                to = "websecure";
                scheme = "https";
                permanent = true;
              };
            };
            websecure = {
              address = "${cfg.address}:443";
              http.tls.certResolver = "cloudflare";
            };
          };
          certificatesResolvers = {
            cloudflare.acme = {
              email = cfg.acmeEmail;
              storage = "/var/lib/traefik/acme-cloudflare.json";
              dnsChallenge = {
                provider = "cloudflare";
                resolvers = ["1.1.1.1:53" "8.8.8.8:53"];
              };
            };
            letsencrypt.acme = {
              email = cfg.acmeEmail;
              storage = "/var/lib/traefik/acme-http.json";
              httpChallenge.entryPoint = "web";
            };
          };
        };
      };

      networking.firewall.allowedTCPPorts = [80 443];

      systemd = {
        tmpfiles.rules = [
          "d /run/homelab-traefik 0750 root traefik -"
          "d /var/lib/traefik 0700 traefik traefik -"
        ];

        services.homelab-traefik-refresh-routes = {
          description = "Resolve direct Traefik routes for homelab services";
          wants = ["docker.service" "network-online.target"];
          after = ["docker.service" "network-online.target"];
          before = ["traefik.service"];
          wantedBy = ["multi-user.target"];
          restartTriggers = [routeSpecFile];
          path = with pkgs; [docker python3];
          serviceConfig = {
            Type = "oneshot";
            UMask = "0027";
          };
          script = ''
            set -euo pipefail
            export ROUTE_SPEC=${lib.escapeShellArg routeSpecFile}
            export ROUTE_OUTPUT=/run/homelab-traefik/routes.yaml

            python3 - <<'PY'
            import grp
            import json
            import os
            import subprocess


            def docker_address(container):
                inspect = subprocess.check_output(["docker", "inspect", container], text=True)
                networks = json.loads(inspect)[0].get("NetworkSettings", {}).get("Networks", {})
                for network_name in ("services", *networks.keys()):
                    network = networks.get(network_name)
                    if network and network.get("IPAddress"):
                        return network["IPAddress"]
                raise RuntimeError(f"Docker container {container} has no bridge address")


            def host_rule(domain, aliases):
                return " || ".join(f"Host(`{name}`)" for name in (domain, *aliases))


            with open(os.environ["ROUTE_SPEC"], "r", encoding="utf-8") as file:
                spec = json.load(file)

            routers = {}
            services = {}
            middlewares = {}
            uses_insecure_transport = False

            for host in spec["hosts"].values():
                name = host["serviceName"]
                middlewares_for_route = []

                if host["dockerContainer"] is not None:
                    address = docker_address(host["dockerContainer"])
                    port = host["dockerPort"]
                else:
                    address = host["upstreamHost"]
                    port = host["upstreamPort"]

                load_balancer = {
                    "passHostHeader": True,
                    "servers": [{"url": f"{host['scheme']}://{address}:{port}"}],
                }
                if host["scheme"] == "https":
                    load_balancer["serversTransport"] = "insecure"
                    uses_insecure_transport = True

                services[name] = {"loadBalancer": load_balancer}

                if host["basicAuthFile"] is not None:
                    middleware = f"{name}-auth"
                    middlewares[middleware] = {
                        "basicAuth": {"usersFile": host["basicAuthFile"]}
                    }
                    middlewares_for_route.append(middleware)

                if host["maxRequestBodyBytes"] is not None:
                    middleware = f"{name}-body-limit"
                    middlewares[middleware] = {
                        "buffering": {"maxRequestBodyBytes": host["maxRequestBodyBytes"]}
                    }
                    middlewares_for_route.append(middleware)

                if host["robotsNoIndex"]:
                    middleware = f"{name}-robots"
                    middlewares[middleware] = {
                        "headers": {
                            "customResponseHeaders": {
                                "X-Robots-Tag": "noindex, nofollow"
                            }
                        }
                    }
                    middlewares_for_route.append(middleware)

                router = {
                    "entryPoints": ["websecure"],
                    "rule": host_rule(host["domain"], host["aliases"]),
                    "service": name,
                    "tls": {"certResolver": host["certResolver"]},
                }
                if middlewares_for_route:
                    router["middlewares"] = middlewares_for_route
                routers[name] = router

                for index, path_route in enumerate(host["pathRoutes"]):
                    path_name = f"{name}-path-{index}"
                    services[path_name] = {
                        "loadBalancer": {
                            "passHostHeader": True,
                            "servers": [
                                {
                                    "url": (
                                        f"http://{path_route['upstreamHost']}:"
                                        f"{path_route['upstreamPort']}"
                                    )
                                }
                            ],
                        }
                    }
                    routers[path_name] = {
                        "entryPoints": ["websecure"],
                        "priority": path_route["priority"],
                        "rule": (
                            f"({host_rule(host['domain'], host['aliases'])})"
                            f" && ({path_route['rule']})"
                        ),
                        "service": path_name,
                        "tls": {"certResolver": host["certResolver"]},
                    }

            redirect_domain = spec["defaultDomainRedirect"]
            if redirect_domain is not None:
                middlewares["default-domain-redirect"] = {
                    "redirectRegex": {
                        "regex": "^https?://[^/]+(.*)",
                        "replacement": f"https://{redirect_domain}''${{1}}",
                        "permanent": True,
                    }
                }
                routers["default-domain-redirect"] = {
                    "entryPoints": ["websecure"],
                    "middlewares": ["default-domain-redirect"],
                    "priority": 1,
                    "rule": "PathPrefix(`/`)",
                    "service": "noop@internal",
                    "tls": {"certResolver": "cloudflare"},
                }

            http = {
                "middlewares": middlewares,
                "routers": routers,
                "services": services,
            }
            if uses_insecure_transport:
                http["serversTransports"] = {
                    "insecure": {"insecureSkipVerify": True}
                }

            routes = {"http": http}

            output = os.environ["ROUTE_OUTPUT"]
            temporary = f"{output}.tmp"
            with open(temporary, "w", encoding="utf-8") as file:
                json.dump(routes, file, indent=2, sort_keys=True)
                file.write("\n")
            os.chown(temporary, 0, grp.getgrnam("traefik").gr_gid)
            os.chmod(temporary, 0o640)
            os.replace(temporary, output)
            PY
          '';
        };

        timers.homelab-traefik-refresh-routes = {
          wantedBy = ["timers.target"];
          timerConfig = {
            OnBootSec = "1min";
            OnUnitActiveSec = "2min";
            Unit = "homelab-traefik-refresh-routes.service";
          };
        };

        services.traefik = {
          requires = ["homelab-traefik-refresh-routes.service"];
          after = ["homelab-traefik-refresh-routes.service"];
        };
      };
    };
  };
}
