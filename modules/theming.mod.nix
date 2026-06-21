{self, ...}: {
  flake.nixosModules.theming = {
    config,
    lib,
    pkgs,
    ...
  }: {
    nixpkgs.overlays = [
      (_: prev: {
        windows-10-theme = self.packages.${prev.stdenv.hostPlatform.system}.windows-10-theme;
      })
    ];

    environment = {
      systemPackages = with pkgs; [
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

      sessionVariables = {
        XCURSOR_THEME = config.theme.cursor;
        XCURSOR_SIZE = toString config.theme.cursorSize;
      };
    };

    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings."org/gnome/desktop/interface" = with lib.gvariant; {
            gtk-theme = config.theme.gtkTheme;
            icon-theme = config.theme.iconTheme;
            font-name = "${config.theme.fonts.sans} 10";
            cursor-theme = config.theme.cursor;
            cursor-size = mkInt32 config.theme.cursorSize;
            color-scheme = "prefer-dark";
          };
        }
      ];
    };

    hjem.users.${config.userName} = {
      rum.misc.gtk = {
        enable = true;
        settings = {
          "theme-name" = config.theme.gtkTheme;
          "icon-theme-name" = config.theme.iconTheme;
          "font-name" = "${config.theme.fonts.sans} 10";
          "cursor-theme-name" = config.theme.cursor;
          "cursor-theme-size" = config.theme.cursorSize;
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
          icon_theme=${config.theme.iconTheme}
        '';

        "qt6ct/qt6ct.conf".text = ''
          [Appearance]
          icon_theme=${config.theme.iconTheme}
        '';
      };

      files.".icons/default/index.theme".text = ''
        [Icon Theme]
        Inherits=${config.theme.cursor}
      '';
    };
  };
}
