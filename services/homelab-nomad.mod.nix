{self, ...}: {
  flake.nixosModules.homelabNomad = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.homelab.services.nomad;
    dataRoot = "${config.homelab.dataRoot}/Services/nomad";
    secretFile = config.sops.templates."nomad-secrets.json".path;
    githubActionsPolicy = pkgs.writeText "nomad-github-actions-policy.hcl" ''
      namespace "staging" {
        policy = "write"
      }

      namespace "production" {
        policy = "write"
      }

      agent {
        policy = "read"
      }

      node {
        policy = "read"
      }

      host_volume "*-staging-data" {
        policy = "write"
      }

      host_volume "*-production-data" {
        policy = "write"
      }
    '';
    githubActionsAuthConfig = pkgs.writeText "nomad-github-actions-auth.json" (builtins.toJSON {
      JWKSURL = "https://token.actions.githubusercontent.com/.well-known/jwks";
      BoundAudiences = [cfg.githubActions.audience];
      BoundIssuer = ["https://token.actions.githubusercontent.com"];
      SigningAlgs = ["RS256"];
      ClaimMappings = {
        environment = "environment";
        ref = "ref";
        repository = "repository";
        repository_owner = "repository_owner";
      };
    });
  in {
    imports = [self.nixosModules.sops];

    options.homelab.services.nomad = {
      enable = lib.mkEnableOption "single-node Nomad hosting platform";

      server = lib.mkEnableOption "Nomad server role";

      client = lib.mkEnableOption "Nomad client role";

      ingress = lib.mkEnableOption "Traefik ingress role";

      githubActions = {
        enable = lib.mkEnableOption "short-lived GitHub Actions Nomad authentication";

        owner = lib.mkOption {
          type = lib.types.str;
          default = "sachahjkl";
          description = "GitHub repository owner allowed to request Nomad deployment tokens.";
        };

        audience = lib.mkOption {
          type = lib.types.str;
          default = "nomad.sacha.house";
          description = "Audience required in GitHub Actions identity tokens.";
        };
      };

      nodeClass = lib.mkOption {
        type = lib.types.str;
        default = "general";
        description = "Nomad node class used for capability-based job placement.";
      };

      serverCount = lib.mkOption {
        type = lib.types.ints.positive;
        default = 1;
        description = "Number of Nomad servers expected during cluster bootstrap.";
      };

      serverAddresses = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Private addresses of Nomad servers used by this client.";
      };

      address = lib.mkOption {
        type = lib.types.str;
        description = "Stable private address of this Nomad agent.";
      };

      interface = lib.mkOption {
        type = lib.types.str;
        default = "ts0";
        description = "Private network interface that accepts Nomad API and cluster traffic.";
      };
    };

    config = lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.server || cfg.client || cfg.ingress;
          message = "An enabled Nomad platform must declare at least one role.";
        }
        {
          assertion = !cfg.client || cfg.serverAddresses != [];
          message = "A Nomad client must declare at least one server address.";
        }
      ];

      sops = {
        secrets = {
          "nomad/gossip-key" = {
            sopsFile = self + /secrets/homelab.yaml;
            owner = "root";
            group = "root";
            mode = "0400";
          };
          "nomad/traefik-token" = lib.mkIf cfg.ingress {
            sopsFile = self + /secrets/homelab.yaml;
            owner = "traefik";
            group = "traefik";
            mode = "0400";
          };
          "nomad/management-token" = lib.mkIf (cfg.server && cfg.githubActions.enable) {
            sopsFile = self + /secrets/homelab.yaml;
            key = "nomad/management-token";
            owner = "root";
            group = "root";
            mode = "0400";
          };
        };
        templates = {
          "traefik-nomad.env" = lib.mkIf cfg.ingress {
            owner = "traefik";
            group = "traefik";
            mode = "0400";
            content = ''
              NOMAD_TOKEN=${config.sops.placeholder."nomad/traefik-token"}
            '';
          };
          "nomad-secrets.json" = {
            owner = "root";
            group = "root";
            mode = "0400";
            content = builtins.toJSON {
              server.encrypt = config.sops.placeholder."nomad/gossip-key";
            };
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d ${dataRoot} 0700 root root -"
        "d ${dataRoot}/alloc 0711 root root -"
        "d ${dataRoot}/state 0700 root root -"
        "d ${dataRoot}/volumes 0711 root root -"
      ];

      services.nomad = {
        enable = true;
        dropPrivileges = false;
        enableDocker = true;
        extraPackages = [pkgs.cni-plugins];
        extraSettingsPaths = [secretFile];
        settings = {
          name = config.networking.hostName;
          region = "global";
          datacenter = "homelab";
          data_dir = "${dataRoot}/state";
          bind_addr = cfg.address;
          advertise = {
            http = "${cfg.address}:4646";
            rpc = "${cfg.address}:4647";
            serf = "${cfg.address}:4648";
          };
          addresses = {
            http = cfg.address;
            rpc = cfg.address;
            serf = cfg.address;
          };
          server = {
            enabled = cfg.server;
            bootstrap_expect = cfg.serverCount;
          };
          client = {
            enabled = cfg.client;
            servers = map (address: "${address}:4647") cfg.serverAddresses;
            network_interface = cfg.interface;
            alloc_dir = "${dataRoot}/alloc";
            cni_path = "${pkgs.cni-plugins}/bin";
            host_volumes_dir = "${dataRoot}/volumes";
            node_class = cfg.nodeClass;
            host_network.loopback = {
              cidr = "127.0.0.1/32";
            };
            options = {
              "driver.raw_exec.enable" = "0";
              "docker.volumes.enabled" = "true";
            };
          };
          acl = {
            enabled = true;
            token_ttl = "30s";
            policy_ttl = "30s";
            role_ttl = "30s";
          };
          telemetry = {
            publish_allocation_metrics = true;
            publish_node_metrics = true;
            prometheus_metrics = true;
          };
        };
      };

      services.traefik = lib.mkIf cfg.ingress {
        enable = true;
        environmentFiles = [config.sops.templates."traefik-nomad.env".path];
        staticConfigOptions = {
          providers.nomad = {
            namespaces = ["staging" "production"];
            exposedByDefault = false;
            watch = true;
            endpoint = {
              address = "http://${cfg.address}:4646";
              token = "$NOMAD_TOKEN";
            };
          };
        };
      };

      systemd.services = {
        nomad = {
          after = ["tailscaled.service" "docker.service"];
          wants = ["tailscaled.service"];
          requires = ["docker.service"];
        };
        traefik = lib.mkIf cfg.ingress {
          after = ["nomad.service"];
          requires = ["nomad.service"];
        };
        nomad-github-actions-auth = lib.mkIf (cfg.server && cfg.githubActions.enable) {
          description = "Configure GitHub Actions authentication in Nomad";
          after = ["nomad.service"];
          requires = ["nomad.service"];
          wantedBy = ["multi-user.target"];
          path = [pkgs.coreutils pkgs.jq pkgs.nomad];
          environment.NOMAD_ADDR = "http://${cfg.address}:4646";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            set -euo pipefail

            export NOMAD_TOKEN="$(cat ${config.sops.secrets."nomad/management-token".path})"

            for _ in $(seq 1 60); do
              if nomad status >/dev/null 2>&1; then
                break
              fi
              sleep 1
            done
            nomad status >/dev/null

            nomad acl policy apply \
              -description "Deploy trusted GitHub repositories to shared application namespaces" \
              github-actions-deploy ${githubActionsPolicy}

            auth_method_args=(
              -type JWT
              -token-locality local
              -max-token-ttl 15m
              -token-name-format "\''${value.repository}"
              -config @${githubActionsAuthConfig}
            )
            if nomad acl auth-method info github-actions >/dev/null 2>&1; then
              nomad acl auth-method update "''${auth_method_args[@]}" github-actions
            else
              nomad acl auth-method create -name github-actions "''${auth_method_args[@]}"
            fi

            configure_rule() {
              local description="$1"
              local selector="$2"
              local rule_id

              rule_id="$(
                nomad acl binding-rule list -json \
                  | jq -r --arg description "$description" \
                    '.[] | select(.AuthMethod == "github-actions" and .Description == $description) | .ID' \
                  | head -n 1
              )"

              if [ -n "$rule_id" ]; then
                nomad acl binding-rule update \
                  -description "$description" \
                  -selector "$selector" \
                  -bind-type policy \
                  -bind-name github-actions-deploy \
                  "$rule_id"
              else
                nomad acl binding-rule create \
                  -description "$description" \
                  -auth-method github-actions \
                  -selector "$selector" \
                  -bind-type policy \
                  -bind-name github-actions-deploy
              fi
            }

            configure_rule \
              "Trusted GitHub staging deployments" \
              'value.repository_owner=="${cfg.githubActions.owner}" and value.ref=="refs/heads/master" and value.environment=="staging"'
            configure_rule \
              "Trusted GitHub production deployments" \
              'value.repository_owner=="${cfg.githubActions.owner}" and value.ref=="refs/heads/master" and value.environment=="production"'
          '';
        };
      };

      networking.firewall.interfaces.${cfg.interface} = {
        allowedTCPPorts = [4646 4647 4648];
        allowedUDPPorts = [4648];
      };

      environment = {
        systemPackages = [pkgs.nomad];
        variables.NOMAD_ADDR = "http://${cfg.address}:4646";
      };
    };
  };
}
