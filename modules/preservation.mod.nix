_: {
  flake.nixosModules.preservation = {
    config,
    lib,
    ...
  }: let
    user = config.userName;
  in {
    options.persist = {
      enable =
        lib.mkEnableOption "ephemeral root state preservation"
        // {
          default = true;
        };

      persistentStoragePath = lib.mkOption {
        type = lib.types.path;
        default = /persist;
        description = "Persistent storage root used by preservation.";
      };

      system = {
        directories = lib.mkOption {
          type = lib.types.listOf (lib.types.oneOf [lib.types.str lib.types.attrs]);
          default = [];
          description = "Additional system directories to persist, typically declared by service or app modules.";
        };

        files = lib.mkOption {
          type = lib.types.listOf (lib.types.oneOf [lib.types.str lib.types.attrs]);
          default = [];
          description = "Additional system files to persist, typically declared by service or app modules.";
        };
      };

      user = {
        directories = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Additional user directories to persist, typically declared by app modules.";
        };

        files = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Additional user files to persist, typically declared by app modules.";
        };
      };
    };

    config = lib.mkIf config.persist.enable {
      # SOPS neededForUsers secrets can be decrypted before preservation bind mounts exist,
      # so key files referenced directly under /persist must have the backing filesystem mounted early.
      fileSystems.${toString config.persist.persistentStoragePath}.neededForBoot = lib.mkDefault true;

      preservation = {
        enable = true;
        preserveAt.${toString config.persist.persistentStoragePath} = {
          commonMountOptions = [
            "x-gvfs-hide"
            "x-gdu.hide"
          ];

          directories =
            [
              {
                directory = "/etc/NetworkManager/system-connections";
                mode = "0700";
              }
              "/var/lib/AccountsService"
              "/var/lib/NetworkManager"
              "/var/lib/bluetooth"
              "/var/lib/libvirt"
              "/var/lib/nixos"
              "/var/lib/sops-nix"
              {
                directory = "/var/lib/sbctl";
                mode = "0700";
              }
              "/var/lib/systemd/coredump"
              "/var/log"
            ]
            ++ config.persist.system.directories;

          files =
            [
              {
                file = "/etc/machine-id";
                inInitrd = true;
              }
            ]
            ++ config.persist.system.files;

          users.${user} = {
            # $HOME is on the tmpfs and these folders are bind mounts from
            # the persistent filesystem. GLib uses ~/.local/share/Trash only
            # for files on $HOME's own device; for the others it uses a
            # .Trash-<uid> at the top of their mount, which it allows only on
            # mounts marked x-gvfs-trash. trash:/// shows them all.
            commonMountOptions = ["x-gvfs-trash"];
            directories = lib.unique ([
                ".cache"
                ".gnupg"
                ".local/share/applications"
                ".local/share/keyrings"
                ".local/state"
                ".ssh"
                "Desktop"
                "Documents"
                "Downloads"
                "Music"
                "Pictures"
                "Projects"
                "Public"
                "Templates"
                "Videos"
              ]
              ++ config.persist.user.directories);

            files = config.persist.user.files;
          };
        };
      };
      systemd = {
        # The service is useless on ephemeral rootfs (already handled by preservation).
        services.systemd-machine-id-commit.enable = false;

        # /tmp is on the tmpfs root: a file there uses memory, and the root is
        # small. /tmp/disk is a folder of the persistent disk, for large
        # temporary files (builds, virtual machine disks): TMPDIR=/tmp/disk.
        # systemd-tmpfiles removes what is older than 7 days.
        tmpfiles.rules = [
          "d ${toString config.persist.persistentStoragePath}/tmp-disk 1777 root root 7d"
        ];
        mounts = [
          {
            description = "Large temporary files, on the persistent disk";
            what = "${toString config.persist.persistentStoragePath}/tmp-disk";
            where = "/tmp/disk";
            type = "none";
            options = "bind";
            # The source folder is made by systemd-tmpfiles.
            after = ["systemd-tmpfiles-setup.service"];
            requires = ["systemd-tmpfiles-setup.service"];
            wantedBy = ["multi-user.target"];
          }
        ];
      };
    };
  };
}
