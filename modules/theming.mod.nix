{ self, ... }:

{
  flake.nixosModules.theming = { config, lib, pkgs, ... }: {
    nixpkgs.overlays = [
      (_: prev: {
        windows-10-theme = self.packages.${prev.stdenv.hostPlatform.system}.windows-10-theme;
      })
    ];

    environment.systemPackages = with pkgs; [
      arc-theme
      adwaita-icon-theme
      dconf
      glib
      morewaita-icon-theme
      papirus-icon-theme
      posy-cursors
      windows10-icons
      windows-10-theme
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
      rum.misc.gtk = {
        enable = true;
        settings = {
          "theme-name" = config.preferences.theme.gtkTheme;
          "icon-theme-name" = config.preferences.theme.iconTheme;
          "font-name" = "${config.preferences.theme.fonts.sans} 10";
          "cursor-theme-name" = config.preferences.theme.cursor;
          "cursor-theme-size" = config.preferences.theme.cursorSize;
          "xft-antialias" = 1;
          "xft-hinting" = 1;
          "xft-hintstyle" = "hintfull";
          "xft-rgba" = "rgb";
          "application-prefer-dark-theme" = true;
        };
      };

      xdg.config.files = {
        "qt5ct/qt5ct.conf".text = ''
          [Appearance]
          icon_theme=${config.preferences.theme.iconTheme}
        '';

        "qt6ct/qt6ct.conf".text = ''
          [Appearance]
          icon_theme=${config.preferences.theme.iconTheme}
        '';
      };

      files.".icons/default/index.theme".text = ''
        [Icon Theme]
        Inherits=${config.preferences.theme.cursor}
      '';
    };
  };
}
