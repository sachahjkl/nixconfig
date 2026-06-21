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

      preferences.theme = {
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
        };
      };
    };
  };
}
