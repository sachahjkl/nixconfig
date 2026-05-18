{ ... }:

{
  flake.nixosModules.hyprlandApps = { config, ... }: {
    hjem.users.${config.userName}.xdg.config.files = {
      "uwsm/env".text = ''
        export XCURSOR_THEME=${config.preferences.theme.cursor}
        export XCURSOR_SIZE=${toString config.preferences.theme.cursorSize}
        export HYPRCURSOR_SIZE=${toString config.preferences.theme.cursorSize}
        export QT_QPA_PLATFORM=wayland
        export QT_QPA_PLATFORMTHEME=qt5ct
        export QT_STYLE_OVERRIDE=kvantum
        export TERMINAL=kitty
        export NIXOS_OZONE_WL=1
        export QT_SCALE_FACTOR=1
      '';

    };
  };
}
