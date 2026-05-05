{ config, lib, ... }:

let
  isHypr = lib.elem config.desktop.environment [ "hyprland" "both" ];
  userName = config.sacha.userName;
in
lib.mkIf isHypr {
  home-manager.users.${userName}.xdg.configFile = {
    "uwsm/env".text = ''
      export XCURSOR_SIZE=${toString config.sacha.theme.cursorSize}
      export HYPRCURSOR_SIZE=${toString config.sacha.theme.cursorSize}
      export QT_QPA_PLATFORM=wayland
      export TERMINAL=kitty
      export NIXOS_OZONE_WL=1
      export QT_SCALE_FACTOR=1
    '';

    "kitty/kitty.conf".text = ''
      font_size 12.0
      background_opacity 0.90
      window_padding_width 5
    '';

    "rofi/config.rasi".text = ''
      @theme "${config.sacha.theme.rofiTheme}"

      configuration {
        modi: "drun,run,window";
        show-icons: true;
      }
    '';

    "qt5ct/qt5ct.conf".text = ''
      [Appearance]
      color_scheme_path=
      custom_palette=false
      icon_theme=${config.sacha.theme.iconTheme}
      standard_dialogs=default
      style=kvantum

      [Fonts]
      fixed="${config.sacha.theme.fonts.mono},12,-1,5,50,0,0,0,0,0"
      general="${config.sacha.theme.fonts.sans},12,-1,5,50,0,0,0,0,0"
    '';

    "qt6ct/qt6ct.conf".text = ''
      [Appearance]
      color_scheme_path=
      custom_palette=false
      icon_theme=${config.sacha.theme.iconTheme}
      standard_dialogs=default
      style=kvantum

      [Fonts]
      fixed="${config.sacha.theme.fonts.mono},12,-1,5,50,0,0,0,0,0"
      general="${config.sacha.theme.fonts.sans},12,-1,5,50,0,0,0,0,0"
    '';

    "Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=${config.sacha.theme.kvantumTheme}
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
