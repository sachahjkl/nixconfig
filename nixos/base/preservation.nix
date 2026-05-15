{ ... }:

{
  flake.nixosModules.preservation = { config, lib, ... }:
    let
      user = config.sacha.userName;
    in
    {
      options.sacha.preservation = {
        enable = lib.mkEnableOption "ephemeral root state preservation" // {
          default = true;
        };

        persistentStoragePath = lib.mkOption {
          type = lib.types.path;
          default = /persist;
          description = "Persistent storage root used by preservation.";
        };

        system = {
          directories = lib.mkOption {
            type = lib.types.listOf (lib.types.oneOf [ lib.types.str lib.types.attrs ]);
            default = [ ];
            description = "Additional system directories to persist, typically declared by service or app modules.";
          };

          files = lib.mkOption {
            type = lib.types.listOf (lib.types.oneOf [ lib.types.str lib.types.attrs ]);
            default = [ ];
            description = "Additional system files to persist, typically declared by service or app modules.";
          };
        };

        user = {
          directories = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Additional user directories to persist, typically declared by app modules.";
          };

          files = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Additional user files to persist, typically declared by app modules.";
          };
        };
      };

      config = lib.mkIf config.sacha.preservation.enable {
        preservation = {
          enable = true;
          preserveAt.${toString config.sacha.preservation.persistentStoragePath} = {
            commonMountOptions = [
              "x-gvfs-hide"
              "x-gdu.hide"
            ];

            directories = [
              { directory = "/etc/NetworkManager/system-connections"; mode = "0700"; }
              "/var/lib/AccountsService"
              "/var/lib/NetworkManager"
              "/var/lib/bluetooth"
              "/var/lib/libvirt"
              "/var/lib/nixos"
              "/var/lib/systemd/coredump"
              "/var/lib/tailscale"
              "/var/log"
            ] ++ config.sacha.preservation.system.directories;

            files = [
              { file = "/etc/machine-id"; inInitrd = true; }
            ] ++ config.sacha.preservation.system.files;

            users.${user} = {
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
              ] ++ config.sacha.preservation.user.directories);

              files = config.sacha.preservation.user.files;
            };
          };
        };
        # The service is useless on ephemeral rootfs (already handled by preservation).
        systemd.services.systemd-machine-id-commit.enable = false;
      };
    };
}
