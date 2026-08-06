_: {
  flake.nixosModules.wslContainers = {
    pkgs,
    ...
  }: {
    config = {
      virtualisation.docker = {
        enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
          flags = ["--all" "--volumes"];
        };
        daemon.settings = {
          live-restore = false;
          log-driver = "json-file";
          log-opts = {
            max-file = "3";
            max-size = "50m";
          };
          storage-driver = "overlay2";
        };
      };

      environment.systemPackages = with pkgs; [
        docker-compose
      ];

      # Docker 29.x with iptables-nft needs `nft` in its PATH to manage rules.
      systemd.services.docker.path = [pkgs.nftables];
    };
  };
}
