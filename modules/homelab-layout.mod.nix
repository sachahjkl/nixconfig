_: {
  flake.nixosModules.homelabLayout = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.homelab;
    inherit (lib) mkOption types;
  in {
    options.homelab = {
      lanInterface = mkOption {
        type = types.str;
        default = "eno1";
      };

      dataRoot = mkOption {
        type = types.str;
        default = "/data";
      };
    };

    config = {
      users = {
        groups = {
          users.gid = 100;
          docker.gid = lib.mkForce 118;
        };

        users = {
          ${config.userName} = {
            uid = 1000;
            group = "users";
            home = config.homeDirectory;
            createHome = true;
          };

          docker = {
            isSystemUser = true;
            uid = 1002;
            group = "users";
            home = "${cfg.dataRoot}/Home/docker";
            createHome = true;
          };

          valentin = {
            isNormalUser = true;
            uid = 1003;
            group = "users";
            home = "${cfg.dataRoot}/Home/valentin";
            createHome = true;
            shell = pkgs.fish;
          };
        };
      };

      networking.hostId = "e7c50a22";

      systemd = {
        network = {
          wait-online.enable = true;
          networks."10-lan" = {
            # Match any Ethernet port instead of a fixed name, so the connected NIC
            # gets DHCP regardless of how the firmware names it.
            matchConfig.Type = "ether";
            networkConfig = {
              DHCP = "yes";
              IPv6AcceptRA = true;
            };
            linkConfig.RequiredForOnline = "routable";
          };
        };

        tmpfiles.rules = [
          "d ${cfg.dataRoot} 0755 root root -"
          "d ${cfg.dataRoot}/Agents 2775 root users -"
          "d ${cfg.dataRoot}/Backups 2770 root users -"
          "d ${cfg.dataRoot}/Docker 2775 root users -"
          "d ${cfg.dataRoot}/Docker/appdata 2775 root users -"
          "d ${cfg.dataRoot}/Docker/backup 2775 root users -"
          "d ${cfg.dataRoot}/Docker/data 2775 root users -"
          "d ${cfg.dataRoot}/Docker/storage 0710 root root -"
          "d ${cfg.dataRoot}/Downloads 2775 root users -"
          "d ${cfg.dataRoot}/Games 2775 root users -"
          "d ${cfg.dataRoot}/Home 2775 root users -"
          "d ${config.homeDirectory} 2775 ${config.userName} users -"
          "d ${cfg.dataRoot}/Home/docker 2775 docker users -"
          "d ${cfg.dataRoot}/Home/valentin 2775 valentin users -"
          "d ${cfg.dataRoot}/Media 2775 root users -"
          "d ${cfg.dataRoot}/Media/Movies 2775 root users -"
          "d ${cfg.dataRoot}/Media/Series 2775 root users -"
          "d ${cfg.dataRoot}/Secrets 0770 root users -"
          "d ${cfg.dataRoot}/VMs 2775 root users -"
        ];
      };
    };
  };
}
