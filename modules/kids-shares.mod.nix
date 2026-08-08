_: {
  flake.nixosModules.kidsShares = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.kidsDesktop.shares;
    nfsMountType = lib.types.submodule {
      options = {
        source = lib.mkOption {
          type = lib.types.str;
          description = "Remote NFS export.";
        };

        mountPoint = lib.mkOption {
          type = lib.types.str;
          description = "Local NFS mount point.";
        };

        options = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "noauto"
            "x-systemd.automount"
            "x-systemd.idle-timeout=10min"
            "x-systemd.mount-timeout=10s"
          ];
          description = "NFS mount options.";
        };
      };
    };
    sambaShareType = lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Name shown in the application menu.";
        };

        uri = lib.mkOption {
          type = lib.types.str;
          description = "Samba share URI.";
        };
      };
    };
    sambaLaunchers = lib.mapAttrsToList (id: share:
      pkgs.makeDesktopItem {
        name = "kids-share-${id}";
        desktopName = share.name;
        comment = "Open ${share.uri}";
        exec = "${lib.getExe' pkgs.xdg-utils "xdg-open"} ${lib.escapeShellArg share.uri}";
        icon = "folder-remote";
        categories = ["Network"];
      })
    cfg.samba;
  in {
    options.kidsDesktop.shares = {
      enable = lib.mkEnableOption "home network shares" // {default = true;};

      nfs = lib.mkOption {
        type = lib.types.attrsOf nfsMountType;
        default = {
          homelab = {
            source = "homelab.local:/";
            mountPoint = "/mnt/homelab";
          };
        };
        description = "NFS exports mounted on demand.";
      };

      samba = lib.mkOption {
        type = lib.types.attrsOf sambaShareType;
        default = {
          downloads = {
            name = "Homelab Downloads";
            uri = "smb://homelab.local/Downloads";
          };
          files = {
            name = "Homelab Files";
            uri = "smb://homelab.local/Filebrowser";
          };
        };
        description = "Samba shares exposed as application launchers.";
      };
    };

    config = lib.mkIf cfg.enable {
      boot.supportedFilesystems = ["nfs"];

      environment.systemPackages =
        [
          pkgs.cifs-utils
          pkgs.nfs-utils
        ]
        ++ sambaLaunchers;

      fileSystems = lib.mapAttrs' (_: mount:
        lib.nameValuePair mount.mountPoint {
          device = mount.source;
          fsType = "nfs";
          inherit (mount) options;
        })
      cfg.nfs;
    };
  };
}
