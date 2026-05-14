{ config, lib, pkgs, ... }:

let
  isHypr = lib.elem config.desktop.environment [ "hyprland" "both" "all" ];
  userName = config.sacha.userName;
in
lib.mkIf isHypr {
  hjem.users.${userName}.xdg.config.files = {
    "uwsm/env".text = ''
      export XCURSOR_SIZE=${toString config.sacha.theme.cursorSize}
      export HYPRCURSOR_SIZE=${toString config.sacha.theme.cursorSize}
      export QT_QPA_PLATFORM=wayland
      export QT_QPA_PLATFORMTHEME=qt5ct
      export QT_STYLE_OVERRIDE=kvantum
      export TERMINAL=kitty
      export NIXOS_OZONE_WL=1
      export QT_SCALE_FACTOR=1
    '';

    "rofi/config.rasi".text = ''
      @theme "${config.sacha.theme.rofiTheme}"

      configuration {
        modi: "drun,run,window";
        show-icons: true;
      }
    '';

    "fontconfig/fonts.conf".text = ''
      <?xml version='1.0'?>
      <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
      <fontconfig>
        <alias><family>sans-serif</family><prefer><family>${config.sacha.theme.fonts.sans}</family></prefer></alias>
        <alias><family>serif</family><prefer><family>Noto Serif</family></prefer></alias>
        <alias><family>monospace</family><prefer><family>${config.sacha.theme.fonts.mono}</family></prefer></alias>
      </fontconfig>
    '';
  };
}
