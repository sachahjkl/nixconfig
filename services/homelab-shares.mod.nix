_: {
  flake.nixosModules.homelabShares = {config, ...}: let
    dataRoot = config.homelab.dataRoot;
    lanInterface = config.homelab.lanInterface;
  in {
    config = {
      persist.system.directories = [
        "/var/lib/nfs"
        "/var/lib/samba"
      ];

      services = {
        samba = {
          enable = true;
          openFirewall = true;
          settings = {
            global = {
              "bind interfaces only" = "yes";
              "disable spoolss" = "yes";
              "dns proxy" = "no";
              "load printers" = "no";
              "hosts allow" = "192.168.50. 127.0.0.1 localhost";
              "interfaces" = "lo ${lanInterface}";
              "map to guest" = "Bad User";
              "server string" = "%h server";
              "socket options" = "TCP_NODELAY IPTOS_LOWDELAY";
              "wins support" = "yes";
              "fruit:nfs_aces" = "no";
              "fruit:copyfile" = "yes";
              "fruit:aapl" = "yes";
            };

            Downloads = {
              path = "${dataRoot}/Downloads";
              "read only" = "no";
              "guest ok" = "yes";
              "guest only" = "yes";
              "create mask" = "0664";
              "directory mask" = "0775";
              "force create mode" = "0664";
              "force directory mode" = "0775";
              "hide special files" = "yes";
              "store dos attributes" = "no";
            };

            Filebrowser = {
              path = dataRoot;
              "read only" = "yes";
              "guest ok" = "yes";
              "create mask" = "0664";
              "directory mask" = "0775";
              "force create mode" = "0664";
              "force directory mode" = "0775";
              "hide special files" = "yes";
              "store dos attributes" = "no";
            };
          };
        };

        samba-wsdd = {
          enable = true;
          openFirewall = true;
        };

        nfs.server = {
          enable = true;
          exports = ''
            ${dataRoot}/Downloads 192.168.50.0/24(rw,subtree_check,insecure)
            ${dataRoot} 192.168.50.0/24(ro,fsid=0,root_squash,subtree_check,insecure)
          '';
        };
      };

      networking.firewall.allowedTCPPorts = [
        22
        80
        81
        111
        139
        443
        445
        2049
        3245
        3246
        3670
        4857
        5055
        7878
        8096
        8920
        8989
        9080
        9696
      ];

      networking.firewall.allowedUDPPorts = [
        111
        137
        138
        1900
        4857
        7359
      ];
    };
  };
}
