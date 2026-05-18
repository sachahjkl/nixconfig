{ ... }:

{
  flake.nixosModules.theming = { config, lib, pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      arc-theme
      dconf
      glib
      papirus-icon-theme
      posy-cursors
    ];

    environment.sessionVariables = {
      XCURSOR_THEME = config.preferences.theme.cursor;
      XCURSOR_SIZE = toString config.preferences.theme.cursorSize;
    };

    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings."org/gnome/desktop/interface" = with lib.gvariant; {
            gtk-theme = config.preferences.theme.gtkTheme;
            icon-theme = config.preferences.theme.iconTheme;
            font-name = "${config.preferences.theme.fonts.sans} 10";
            cursor-theme = config.preferences.theme.cursor;
            cursor-size = mkInt32 config.preferences.theme.cursorSize;
            color-scheme = "prefer-dark";
          };
        }
      ];
    };

    hjem.users.${config.userName} = {
      files.".icons/default/index.theme".text = ''
        [Icon Theme]
        Inherits=${config.preferences.theme.cursor}
      '';

      xdg.config.files = {
        "gtk-3.0/settings.ini".text = ''
          [Settings]
          gtk-theme-name=${config.preferences.theme.gtkTheme}
          gtk-icon-theme-name=${config.preferences.theme.iconTheme}
          gtk-font-name=${config.preferences.theme.fonts.sans} 10
          gtk-cursor-theme-name=${config.preferences.theme.cursor}
          gtk-cursor-theme-size=${toString config.preferences.theme.cursorSize}
          gtk-xft-antialias=1
          gtk-xft-hinting=1
          gtk-xft-hintstyle=hintfull
          gtk-xft-rgba=rgb
        '';

        "gtk-4.0/settings.ini".text = ''
          [Settings]
          gtk-theme-name=${config.preferences.theme.gtkTheme}
          gtk-icon-theme-name=${config.preferences.theme.iconTheme}
          gtk-font-name=${config.preferences.theme.fonts.sans} 10
          gtk-cursor-theme-name=${config.preferences.theme.cursor}
          gtk-cursor-theme-size=${toString config.preferences.theme.cursorSize}
          gtk-xft-antialias=1
          gtk-xft-hinting=1
          gtk-xft-hintstyle=hintfull
          gtk-xft-rgba=rgb
        '';
      };
    };
  };
}
