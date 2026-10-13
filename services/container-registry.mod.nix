{self, ...}: {
  flake.nixosModules.containerRegistry = {
    config,
    lib,
    options,
    ...
  }: let
    cfg = config.services.containerRegistry;
    certificate = config.security.acme.certs.${cfg.domain}.directory;
    hasK3s = lib.hasAttrByPath ["services" "k3s" "enable"] options;
    k3sEnabled = lib.attrByPath ["services" "k3s" "enable"] false config;
  in {
    imports = [self.nixosModules.sops];

    options.services.containerRegistry = {
      enable = lib.mkEnableOption "private container registry reachable over Tailscale";

      domain = lib.mkOption {
        type = lib.types.str;
        description = "DNS name resolving to the private registry address.";
      };

      address = lib.mkOption {
        type = lib.types.str;
        description = "Tailscale address of the registry listener.";
      };

      interface = lib.mkOption {
        type = lib.types.str;
        description = "Private interface accepting registry traffic.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        # 443 on the Tailscale address belongs to Tailscale Funnel.
        default = 5443;
        description = "HTTPS port of the registry; image names carry it (domain:port/name).";
      };

      dataDir = lib.mkOption {
        type = lib.types.str;
        description = "Persistent directory holding image layers and manifests.";
      };

      acmeEmail = lib.mkOption {
        type = lib.types.str;
        description = "Contact email for the TLS certificate.";
      };

      cloudflareSopsFile = lib.mkOption {
        type = lib.types.path;
        description = "SOPS file containing the Cloudflare DNS token.";
      };

      credentialsSopsFile = lib.mkOption {
        type = lib.types.path;
        description = "SOPS file containing registry/htpasswd (bcrypt) and registry/password.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "homelab";
        description = "Account name in the htpasswd file, also used by k3s to pull images.";
      };
    };

    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        # Pinned like traefik and openbao: an automatic id can change and lock the registry out of its data.
        users.groups.docker-registry.gid = 985;
        users.users.docker-registry.uid = 985;

        sops.secrets = {
          "registry/cloudflare-dns" = {
            sopsFile = cfg.cloudflareSopsFile;
            key = "cloudflare/dns";
          };
          "registry/htpasswd" = {
            sopsFile = cfg.credentialsSopsFile;
            owner = "docker-registry";
            group = "docker-registry";
            mode = "0400";
            restartUnits = ["docker-registry.service"];
          };
        };

        security.acme = {
          acceptTerms = true;
          certs.${cfg.domain} = {
            email = cfg.acmeEmail;
            dnsProvider = "cloudflare";
            credentialFiles.CF_DNS_API_TOKEN_FILE = config.sops.secrets."registry/cloudflare-dns".path;
            group = "docker-registry";
            reloadServices = ["docker-registry.service"];
          };
        };

        services.dockerRegistry = {
          enable = true;
          listenAddress = cfg.address;
          inherit (cfg) port;
          storagePath = cfg.dataDir;
          enableDelete = true;
          enableGarbageCollect = true;
          garbageCollectDates = "weekly";
          extraConfig = {
            http = {
              host = "https://${cfg.domain}:${toString cfg.port}";
              tls = {
                certificate = "${certificate}/fullchain.pem";
                key = "${certificate}/key.pem";
              };
            };
            auth.htpasswd = {
              realm = cfg.domain;
              path = config.sops.secrets."registry/htpasswd".path;
            };
          };
        };

        networking.firewall.interfaces.${cfg.interface}.allowedTCPPorts = [cfg.port];

        systemd = {
          tmpfiles.rules = [
            "d ${cfg.dataDir} 0750 docker-registry docker-registry -"
            # Ownership restored on every boot, file modes left untouched.
            "Z ${cfg.dataDir} - docker-registry docker-registry -"
          ];

          services.docker-registry = {
            # The listener binds the Tailscale address, which only exists once tailscaled is up.
            wants = ["network-online.target"];
            requires = ["acme-${cfg.domain}.service"];
            after = ["network-online.target" "tailscaled.service" "acme-${cfg.domain}.service"];
            unitConfig.RequiresMountsFor = [cfg.dataDir];
            serviceConfig = {
              Restart = "on-failure";
              RestartSec = "10s";
            };
          };
        };
      }

      # k3s pulls from the registry with the same account; the file holds the password.
      (lib.optionalAttrs hasK3s {
        sops = lib.mkIf k3sEnabled {
          secrets."registry/password".sopsFile = cfg.credentialsSopsFile;
          templates."k3s-registries.yaml" = {
            path = "/etc/rancher/k3s/registries.yaml";
            mode = "0400";
            restartUnits = ["k3s.service"];
            content = builtins.toJSON {
              configs."${cfg.domain}:${toString cfg.port}".auth = {
                username = cfg.user;
                password = config.sops.placeholder."registry/password";
              };
            };
          };
        };
      })
    ]);
  };
}
