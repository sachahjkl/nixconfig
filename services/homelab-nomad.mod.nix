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
  in {
    imports = [self.nixosModules.sops];

    options.homelab.services.nomad = {
      enable = lib.mkEnableOption "single-node Nomad hosting platform";

      server = lib.mkEnableOption "Nomad server role";

      client = lib.mkEnableOption "Nomad client role";

      ingress = lib.mkEnableOption "Traefik ingress role";

      nodeClass = lib.mkOption {
        type = lib.types.str;
        default = "general";
        description = "Nomad node class used for capability-based job placement.";
      };

      address = lib.mkOption {
        type = lib.types.str;
        description = "Stable private address used by Nomad servers, clients, and API consumers.";
      };

      interface = lib.mkOption {
        type = lib.types.str;
        default = "ts0";
        description = "Private network interface that accepts Nomad API and cluster traffic.";
      };
    };

    config = lib.mkIf cfg.enable {
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
          name = "homelab";
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
            bootstrap_expect = 1;
          };
          client = {
            enabled = cfg.client;
            servers = ["${cfg.address}:4647"];
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
