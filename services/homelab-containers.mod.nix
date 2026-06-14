_: {
  flake.nixosModules.homelabContainers = {
    config,
    pkgs,
    ...
  }: let
    dataRoot = config.homelab.dataRoot;
  in {
    config = {
      preferences.preservation.system.directories = [
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
