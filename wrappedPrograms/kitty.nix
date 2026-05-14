{ inputs, lib, self, ... }:

{
  flake.wrappersModules.kitty = { config, lib, ... }: {
    options.shell = lib.mkOption {
      type = lib.types.str;
      default = "";
    };

    config = {
      args = lib.mkAfter (lib.optionals (config.shell != "") [ config.shell ]);
      settings = {
        enable_audio_bell = "no";
        font_family = "JetBrainsMono Nerd Font";
        font_size = 12;
        allow_remote_control = "yes";
        shell_integration = "enabled";
        background = self.lib.terminalTheme.background;
        foreground = self.lib.terminalTheme.foreground;
        cursor = self.lib.terminalTheme.cursorColor;
        selection_background = self.lib.terminalTheme.selectionBackground;
        color0 = self.lib.terminalTheme.black;
        color1 = self.lib.terminalTheme.red;
        color2 = self.lib.terminalTheme.green;
        color3 = self.lib.terminalTheme.yellow;
        color4 = self.lib.terminalTheme.blue;
        color5 = self.lib.terminalTheme.purple;
        color6 = self.lib.terminalTheme.cyan;
        color7 = self.lib.terminalTheme.white;
        color8 = self.lib.terminalTheme.brightBlack;
        color9 = self.lib.terminalTheme.brightRed;
        color10 = self.lib.terminalTheme.brightGreen;
        color11 = self.lib.terminalTheme.brightYellow;
        color12 = self.lib.terminalTheme.brightBlue;
        color13 = self.lib.terminalTheme.brightPurple;
        color14 = self.lib.terminalTheme.brightCyan;
        color15 = self.lib.terminalTheme.brightWhite;
        background_opacity = "0.85";
        background_blur = "5";
      };
    };
  };

  perSystem = { pkgs, self', ... }: {
    packages.terminal = (inputs.wrappers.wrapperModules.kitty.apply {
      inherit pkgs;
      imports = [ self.wrappersModules.kitty ];
      shell = lib.getExe self'.packages.environment;
    }).wrapper;
  };
}
