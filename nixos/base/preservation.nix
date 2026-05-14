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
              "/var/lib/flatpak"
              "/var/lib/libvirt"
              "/var/lib/nixos"
              "/var/lib/systemd/coredump"
              "/var/lib/tailscale"
              "/var/log"
            ];

            files = [
              { file = "/etc/machine-id"; inInitrd = true; }
            ];

            users.${user} = {
              directories = [
                ".cache"
                ".config/BraveSoftware"
                ".config/chromium"
                ".config/discord"
                ".config/helium"
                ".config/nvim"
                ".config/obs-studio"
                ".gnupg"
                ".local/share/Steam"
                ".local/share/applications"
                ".local/share/direnv"
                ".local/share/fish"
                ".local/share/flatpak"
                ".local/share/keyrings"
                ".local/share/nvim"
                ".local/share/wireplumber"
                ".local/share/zoxide"
                ".local/state"
                ".mozilla"
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
              ];
            };
          };
        };
        # The service is useless on ephemeral rootfs (already handled by preservation).
        systemd.services.systemd-machine-id-commit.enable = false;
      };
    };
}
