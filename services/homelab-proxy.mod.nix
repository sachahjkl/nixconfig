{self, ...}: {
  flake.nixosModules.homelabProxy = {
    config,
    lib,
    ...
  }: let
    inherit
      (lib)
      mkEnableOption
      mkIf
      mkOption
      types
      ;

    cfg = config.homelab.proxy;
    hostEntries = lib.attrValues cfg.hosts;
  in {
    imports = [
      self.nixosModules.cloudflareDns
      self.nixosModules.homelabTraefik
    ];

    options.homelab.proxy = {
      enable = mkEnableOption "Traefik ingress for homelab services";

      address = mkOption {
        type = types.str;
        description = "Address used by the public Traefik entrypoints.";
      };

      acmeEmail = mkOption {
        type = types.str;
        description = "Contact email used for ACME registrations.";
      };

      defaultDomainRedirect = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Domain used by the catch-all HTTPS redirect.";
      };

      hosts = mkOption {
        type = types.attrsOf (types.submodule (_: {
          options = {
            aliases = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Additional domains routed to this service.";
            };

            scheme = mkOption {
              type = types.enum ["http" "https"];
              default = "http";
              description = "Protocol used between Traefik and the service.";
            };

            upstreamHost = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Host name or address of a host service.";
            };

            upstreamPort = mkOption {
              type = types.nullOr types.port;
              default = null;
              description = "Port of a host service.";
            };

            dockerContainer = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Docker container resolved to a bridge address.";
            };

            dockerPort = mkOption {
              type = types.nullOr types.port;
              default = null;
              description = "Port exposed inside the Docker container.";
            };

            basicAuthFile = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "htpasswd file used by the Traefik basic-auth middleware.";
            };

            maxRequestBodyBytes = mkOption {
              type = types.nullOr types.ints.positive;
              default = null;
              description = "Maximum buffered request body size in bytes.";
            };

            robotsNoIndex = mkOption {
              type = types.bool;
              default = false;
              description = "Send an X-Robots-Tag header that blocks search indexing.";
            };

            pathRoutes = mkOption {
              type = types.listOf (types.submodule (_: {
                options = {
                  rule = mkOption {
                    type = types.str;
                    description = "Traefik path rule combined with this host rule.";
                  };
                  upstreamHost = mkOption {
                    type = types.str;
                    description = "Host name or address of the path service.";
                  };
                  upstreamPort = mkOption {
                    type = types.port;
                    description = "Port of the path service.";
                  };
                  priority = mkOption {
                    type = types.int;
                    default = 100;
                    description = "Router priority for this path rule.";
                  };
                };
              }));
              default = [];
              description = "Higher-priority routes for selected paths.";
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

    config = mkIf cfg.enable {
      assertions =
        map
        (hostCfg: {
          assertion =
            (hostCfg.dockerContainer != null && hostCfg.dockerPort != null && hostCfg.upstreamHost == null && hostCfg.upstreamPort == null)
            || (hostCfg.dockerContainer == null && hostCfg.dockerPort == null && hostCfg.upstreamHost != null && hostCfg.upstreamPort != null);
          message = "Each homelab.proxy.hosts entry must define one Docker or host service.";
        })
        hostEntries;
    };
  };
}
