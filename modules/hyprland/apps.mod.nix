_: {
  flake.nixosModules.hyprlandApps = {config, ...}: {
    hjem.users.${config.userName} = {
      environment.sessionVariables = {
        XCURSOR_THEME = config.theme.cursor;
        XCURSOR_SIZE = toString config.theme.cursorSize;
        HYPRCURSOR_SIZE = toString config.theme.cursorSize;
        QT_QPA_PLATFORM = "wayland";
        QT_QPA_PLATFORMTHEME = "qt5ct";
        QT_STYLE_OVERRIDE = "kvantum";
        NIXOS_OZONE_WL = "1";
        QT_SCALE_FACTOR = "1";
      };

      rum.desktops.hyprland.enable = true;
    };
  };
}
