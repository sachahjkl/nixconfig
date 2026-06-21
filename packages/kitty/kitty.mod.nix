{
  inputs,
  lib,
  self,
  ...
}: {
  flake = {
    lib.mkTerminal = {
      pkgs,
      fontFamily ? self.lib.fonts.mono,
      shell ? "",
      terminalTheme ? null,
    }:
      (inputs.wrappers.wrapperModules.kitty.apply {
        inherit pkgs;
        imports = [self.wrappersModules.kitty];
        inherit fontFamily shell terminalTheme;
      }).wrapper;

    wrappersModules.kitty = {
      config,
      lib,
      ...
    }: {
      options = {
        shell = lib.mkOption {
          type = lib.types.str;
          default = "";
        };

        fontFamily = lib.mkOption {
          type = lib.types.str;
          default = self.lib.fonts.mono;
          description = "Kitty font family.";
        };

        terminalTheme = lib.mkOption {
          type = lib.types.nullOr (lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                default = "";
              };
              background = lib.mkOption {type = lib.types.str;};
              black = lib.mkOption {type = lib.types.str;};
              blue = lib.mkOption {type = lib.types.str;};
              brightBlack = lib.mkOption {type = lib.types.str;};
              brightBlue = lib.mkOption {type = lib.types.str;};
              brightCyan = lib.mkOption {type = lib.types.str;};
              brightGreen = lib.mkOption {type = lib.types.str;};
              brightPurple = lib.mkOption {type = lib.types.str;};
              brightRed = lib.mkOption {type = lib.types.str;};
              brightWhite = lib.mkOption {type = lib.types.str;};
              brightYellow = lib.mkOption {type = lib.types.str;};
              cursorColor = lib.mkOption {type = lib.types.str;};
              cyan = lib.mkOption {type = lib.types.str;};
              foreground = lib.mkOption {type = lib.types.str;};
              green = lib.mkOption {type = lib.types.str;};
              purple = lib.mkOption {type = lib.types.str;};
              red = lib.mkOption {type = lib.types.str;};
              selectionBackground = lib.mkOption {type = lib.types.str;};
              white = lib.mkOption {type = lib.types.str;};
              yellow = lib.mkOption {type = lib.types.str;};
            };
          });
          default = null;
          description = "Optional terminal palette to apply to Kitty.";
        };
      };

      config = {
        args = lib.mkAfter (lib.optionals (config.shell != "") [config.shell]);
        settings =
          {
            enable_audio_bell = "no";
            font_family = config.fontFamily;
            font_size = 14;
            allow_remote_control = "yes";
            auto_reload_config = -1;
            shell_integration = "enabled";
            background_opacity = "0.85";
            background_blur = "5";
          }
          // lib.optionalAttrs (config.terminalTheme != null) {
            background = config.terminalTheme.background;
            foreground = config.terminalTheme.foreground;
            cursor = config.terminalTheme.cursorColor;
            selection_background = config.terminalTheme.selectionBackground;
            color0 = config.terminalTheme.black;
            color1 = config.terminalTheme.red;
            color2 = config.terminalTheme.green;
            color3 = config.terminalTheme.yellow;
            color4 = config.terminalTheme.blue;
            color5 = config.terminalTheme.purple;
            color6 = config.terminalTheme.cyan;
            color7 = config.terminalTheme.white;
            color8 = config.terminalTheme.brightBlack;
            color9 = config.terminalTheme.brightRed;
            color10 = config.terminalTheme.brightGreen;
            color11 = config.terminalTheme.brightYellow;
            color12 = config.terminalTheme.brightBlue;
            color13 = config.terminalTheme.brightPurple;
            color14 = config.terminalTheme.brightCyan;
            color15 = config.terminalTheme.brightWhite;
          };
      };
    };

    nixosModules.kitty = {lib, ...}: {
      options.preferences.kitty = {
        theme = lib.mkOption {
          type = lib.types.nullOr lib.types.attrs;
          default = null;
          description = "Optional terminal theme to apply to Kitty.";
        };
      };
    };
  };

  perSystem = {
    pkgs,
    self',
    ...
  }: {
    packages.terminal = self.lib.mkTerminal {
      inherit pkgs;
      shell = lib.getExe self'.packages.userShell;
    };
  };
}
