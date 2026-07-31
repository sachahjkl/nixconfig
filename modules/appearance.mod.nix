{self, ...}: {
  flake.nixosModules.appearance = {lib, ...}: {
    options = {
      assets = {
        wallpaper = lib.mkOption {
          type = lib.types.path;
          description = "Shared wallpaper asset path.";
        };

        faceIcon = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Shared face icon asset path.";
        };
      };

      theme = {
        isDark = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether applications should use dark color variants.";
        };

        cornerRadius = lib.mkOption {
          type = lib.types.int;
          default = 0;
          description = "Shared application corner radius in pixels.";
        };

        terminalPalette = lib.mkOption {
          type = lib.types.attrs;
          default = self.lib.terminalThemes.kittyDefault;
          description = "Shared terminal color palette.";
        };

        padding = lib.mkOption {
          type = lib.types.int;
          default = 8;
          description = "Shared application padding in pixels.";
        };

        cursor = lib.mkOption {
          type = lib.types.str;
          default = "Posy_Cursor_Black_125_175";
          description = "Shared cursor theme name.";
        };

        cursorSize = lib.mkOption {
          type = lib.types.int;
          default = 48;
          description = "Shared cursor size.";
        };

        gtkTheme = lib.mkOption {
          type = lib.types.str;
          default = "Windows-10-Dark";
          description = "Shared GTK theme name.";
        };

        iconTheme = lib.mkOption {
          type = lib.types.str;
          default = "Papirus-Dark";
          description = "Shared icon theme name.";
        };

        rofiTheme = lib.mkOption {
          type = lib.types.str;
          default = "Arc-Dark";
          description = "Shared Rofi theme name.";
        };

        kvantumTheme = lib.mkOption {
          type = lib.types.str;
          default = "Windows-10-Dark";
          description = "Shared Kvantum theme name.";
        };

        fonts = {
          sans = lib.mkOption {
            type = lib.types.str;
            default = self.lib.fonts.sans;
            description = "Shared sans-serif UI font name.";
          };

          mono = lib.mkOption {
            type = lib.types.str;
            default = self.lib.fonts.mono;
            description = "Shared monospace UI font name.";
          };

          size = {
            normal = lib.mkOption {
              type = lib.types.number;
              default = 14;
              description = "Shared normal font size.";
            };

            big = lib.mkOption {
              type = lib.types.number;
              default = 20;
              description = "Shared large font size.";
            };
          };
        };
      };
    };
  };
}
