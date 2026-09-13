_: {
  flake.nixosModules.containerHost = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.containerHost;
    registries = config.virtualisation.containers.registries;
    registriesConfig = (pkgs.formats.toml {}).generate "registries.conf" {
      "unqualified-search-registries" = registries.search;
      registry =
        map (location: {
          inherit location;
          insecure = true;
        })
        registries.insecure
        ++ map (location: {
          inherit location;
          blocked = true;
        })
        registries.block;
    };
  in {
    options.services.containerHost = {
      enable = lib.mkEnableOption "Docker and Podman container host";

      dockerDataRoot = lib.mkOption {
        type = lib.types.str;
        description = "Directory containing Docker state.";
      };

      sharedNetwork = lib.mkOption {
        type = lib.types.str;
        default = "services";
        description = "Docker network shared by local service containers.";
      };
    };

    config = lib.mkIf cfg.enable {
      persist.system.directories = [
        "/var/lib/containers"
      ];

      virtualisation.docker = {
        enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
          flags = ["--all" "--volumes"];
        };
        daemon.settings = {
          data-root = cfg.dockerDataRoot;
          live-restore = false;
          log-driver = "json-file";
          log-opts = {
            max-file = "3";
            max-size = "50m";
          };
          storage-driver = "overlay2";
        };
      };

      virtualisation.podman = {
        enable = true;
        dockerCompat = false;
        defaultNetwork.settings.dns_enabled = true;
      };

      environment.etc."containers/registries.conf".source = lib.mkForce registriesConfig;

      environment.systemPackages = with pkgs; [
        docker-compose
        podman-compose
      ];

      networking.firewall.trustedInterfaces = ["docker0" "podman0"];
      networking.firewall.checkReversePath = "loose";

      # Docker 29.x with iptables-nft needs `nft` in its PATH to manage rules.
      systemd.services.docker.path = [pkgs.nftables];

      systemd.services.docker-create-shared-network = {
        description = "Create the shared Docker network";
        after = ["docker.service"];
        wants = ["docker.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [pkgs.docker];
        script = ''
          network=${lib.escapeShellArg cfg.sharedNetwork}
          docker network inspect "$network" >/dev/null 2>&1 || docker network create "$network"
        '';
      };
    };
  };
}
