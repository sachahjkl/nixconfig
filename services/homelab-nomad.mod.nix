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
      sops.secrets."nomad/gossip-key" = {
        sopsFile = builtins.path {
          path = self + /secrets/homelab.yaml;
          name = "homelab-secrets.yaml";
        };
        owner = "root";
        group = "root";
        mode = "0400";
      };

      sops.templates."nomad-secrets.json" = {
        owner = "root";
        group = "root";
        mode = "0400";
        content = builtins.toJSON {
          server.encrypt = config.sops.placeholder."nomad/gossip-key";
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
            enabled = true;
            bootstrap_expect = 1;
          };
          client = {
            enabled = true;
            servers = ["${cfg.address}:4647"];
            network_interface = cfg.interface;
            alloc_dir = "${dataRoot}/alloc";
            host_volumes_dir = "${dataRoot}/volumes";
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

      systemd.services.nomad = {
        after = ["tailscaled.service" "docker.service"];
        wants = ["tailscaled.service"];
        requires = ["docker.service"];
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
