{self, ...}: {
  flake.nixosModules.nomadPlatform = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.nomadPlatform;
    dataRoot = cfg.dataDir;
    secretFile = config.sops.templates."nomad-secrets.json".path;
    githubActionsPolicies = lib.genAttrs cfg.namespaces (
      namespace:
        pkgs.writeText "nomad-github-actions-${namespace}-policy.hcl" ''
          namespace "*" {
            policy = "read"
          }

          namespace ${builtins.toJSON namespace} {
            policy = "write"
          }

          agent {
            policy = "read"
          }

          node {
            policy = "read"
          }

          host_volume ${builtins.toJSON "*-${namespace}-data"} {
            policy = "write"
          }
        ''
    );
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

    options.services.nomadPlatform = {
      enable = lib.mkEnableOption "Nomad application platform";

      dataDir = lib.mkOption {
        type = lib.types.str;
        description = "Directory containing Nomad state, allocations, and host volumes.";
      };

      datacenter = lib.mkOption {
        type = lib.types.str;
        description = "Nomad datacenter name.";
      };

      region = lib.mkOption {
        type = lib.types.str;
        default = "global";
        description = "Nomad region name.";
      };

      sopsFile = lib.mkOption {
        type = lib.types.path;
        description = "SOPS file containing the Nomad secrets.";
      };

      server = lib.mkEnableOption "Nomad server role";

      client = lib.mkEnableOption "Nomad client role";

      ingress = lib.mkEnableOption "Traefik ingress role";

      githubActions = {
        enable = lib.mkEnableOption "short-lived GitHub Actions Nomad authentication";

        owner = lib.mkOption {
          type = lib.types.str;
          description = "GitHub repository owner allowed to request Nomad deployment tokens.";
        };

        audience = lib.mkOption {
          type = lib.types.str;
          description = "Audience required in GitHub Actions identity tokens.";
        };
      };

      namespaces = lib.mkOption {
        type = lib.types.listOf (lib.types.strMatching "[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?");
        default = [];
        description = "Application namespaces exposed through Nomad and Traefik.";
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
        {
          assertion = !(cfg.ingress || cfg.githubActions.enable) || cfg.namespaces != [];
          message = "Nomad ingress and GitHub Actions authentication require application namespaces.";
        }
      ];

      sops = {
        secrets = {
          "nomad/gossip-key" = {
            inherit (cfg) sopsFile;
            owner = "root";
            group = "root";
            mode = "0400";
          };
          "nomad/traefik-token" = lib.mkIf cfg.ingress {
            inherit (cfg) sopsFile;
            owner = "traefik";
            group = "traefik";
            mode = "0400";
          };
          "nomad/management-token" = lib.mkIf (cfg.server && cfg.githubActions.enable) {
            inherit (cfg) sopsFile;
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
          inherit (cfg) datacenter region;
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
            inherit (cfg) namespaces;
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

            ${lib.concatMapStringsSep "\n" (namespace: ''
                nomad namespace apply ${lib.escapeShellArg namespace}
                nomad acl policy apply \
                  -description "Deploy trusted GitHub repositories to ${namespace}" \
                  github-actions-deploy-${namespace} ${githubActionsPolicies.${namespace}}
              '')
              cfg.namespaces}

            if nomad acl policy info github-actions-deploy >/dev/null 2>&1; then
              nomad acl policy delete github-actions-deploy
            fi

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

            description="Trusted GitHub deployments"
            selector='value.repository_owner=="${cfg.githubActions.owner}" and value.ref=="refs/heads/master"'
            rule_id="$(
              nomad acl binding-rule list -json \
                | jq -r --arg description "$description" \
                  '.[] | select(.AuthMethod == "github-actions" and .Description == $description) | .ID' \
                | head -n 1
            )"

            binding_rule_args=(
              -description "$description"
              -selector "$selector"
              -bind-type policy
              -bind-name "github-actions-deploy-\''${value.environment}"
            )
            if [ -n "$rule_id" ]; then
              nomad acl binding-rule update "''${binding_rule_args[@]}" "$rule_id"
            else
              nomad acl binding-rule create \
                -auth-method github-actions \
                "''${binding_rule_args[@]}"
            fi

            mapfile -t obsolete_rule_ids < <(
              nomad acl binding-rule list -json \
                | jq -r --arg description "$description" \
                  '.[] | select(.AuthMethod == "github-actions" and .Description != $description) | .ID'
            )
            for obsolete_rule_id in "''${obsolete_rule_ids[@]}"; do
              nomad acl binding-rule delete "$obsolete_rule_id"
            done
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
