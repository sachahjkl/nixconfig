_: {
  flake.nixosModules.homelabContainers = {
    config,
    lib,
    pkgs,
    ...
  }: let
    dataRoot = config.homelab.dataRoot;
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
    config = {
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
          data-root = "${dataRoot}/Docker/storage";
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

      systemd.services.docker-create-services-network = {
        description = "Create the shared docker network used by compose stacks";
        after = ["docker.service"];
        wants = ["docker.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [pkgs.docker];
        script = ''
          docker network inspect services >/dev/null 2>&1 || docker network create services
        '';
      };
    };
  };
}
