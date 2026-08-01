_: {
  flake.nixosModules.hyprlandCore = {
    config,
    lib,
    pkgs,
    ...
  }: let
    hyprSessionTarget = "wayland-session@hyprland.desktop.target";
  in {
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
    };

    config = {
      services = {
        displayManager = {
          autoLogin = {
            enable = config.display.autoLoginUser != null;
            user = config.display.autoLoginUser;
          };

          ly = {
            enable = true;
            settings = {
              session_log = null;
              animate = true;
              animation = "colormix";
              clock = "%c";
              bigclock = true;
              colormix_col1 = "0x00FF0100";
              colormix_col2 = "0x00000000";
              colormix_col3 = "0x00FFAA00";
              save = true;
            };
          };
          defaultSession = config.display.defaultSession;
        };
      };

      programs.hyprland = {
        enable = true;
        withUWSM = true;
        package = pkgs.hyprland;
        portalPackage = pkgs.xdg-desktop-portal-hyprland;
        systemd.setPath.enable = true;
      };

      systemd.user.services = {
        hyprpolkitagent = {
          description = "Hyprland Polkit Authentication Agent";
          wantedBy = [hyprSessionTarget];
          partOf = [hyprSessionTarget];
          after = [hyprSessionTarget];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
            Restart = "on-failure";
            RestartSec = 1;
          };
        };

        xdg-desktop-portal-hyprland.serviceConfig = {
          Restart = lib.mkForce "no";
        };
      };
    };
  };
}
