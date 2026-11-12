_: {
  # The screens and the log-on, whatever the session: Hyprland, ShojiWM and the
  # log-on screens read them.
  flake.nixosModules.display = {lib, ...}: {
    # Imported by each session's module: declared once.
    key = "nixconfig#nixosModules.display";

    options.display = {
      defaultSession = lib.mkOption {
        type = lib.types.str;
        default = "hyprland-uwsm";
        description = "Default display-manager session.";
      };

      autoLoginUser = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        # Auto-login skips PAM password entry, leaving GNOME Keyring locked and
        # forcing applications such as Brave to prompt when accessing secrets.
        # default = lib.attrByPath ["userName"] null config;
        default = null;
        description = "User to auto-login through the configured display manager. Set to null to disable.";
      };

      monitors = lib.mkOption {
        type = lib.types.nonEmptyListOf (lib.types.submodule {
          options = {
            output = lib.mkOption {
              type = lib.types.str;
              default = "";
            };
            mode = lib.mkOption {
              type = lib.types.str;
              default = "preferred";
            };
            position = lib.mkOption {
              type = lib.types.str;
              default = "auto";
            };
            scale = lib.mkOption {
              type = lib.types.number;
              default = 1.875;
            };
            colorManagement = lib.mkOption {
              type = lib.types.str;
              default = "auto";
              description = "Hyprland color management preset.";
            };
            hdr = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              description = "Override HDR support. Null uses automatic detection.";
            };
          };
        });
        default = [{}];
        description = "The screens: their connector, mode, position and scale, for every session (Hyprland, ShojiWM) and the log-on screen.";
      };
    };
  };
}
