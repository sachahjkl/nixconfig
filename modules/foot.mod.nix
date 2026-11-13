_: {
  # foot, a light Wayland terminal kept at hand beside the default one. The
  # NixOS module writes /etc/xdg/foot/foot.ini, which foot reads when the user
  # has no foot.ini of their own.
  flake.nixosModules.foot = {
    config,
    lib,
    ...
  }: let
    terminalPreferences = lib.attrByPath ["terminal"] {} config;
    enabled = lib.attrByPath ["foot" "enable"] false terminalPreferences || lib.attrByPath ["default"] null terminalPreferences == "foot";
    palette = lib.attrByPath ["foot" "theme"] config.theme.terminalPalette terminalPreferences;
    # foot takes colours without the leading #.
    colour = lib.removePrefix "#";
  in {
    config = lib.mkIf enabled {
      programs.foot = {
        enable = true;
        # OSC 7 and 133: a new window (Ctrl+Shift+N) opens in the shell's
        # folder, and Ctrl+Shift+Z/X jump between prompts.
        enableFishIntegration = true;
        enableBashIntegration = true;
        settings = {
          main = {
            # Points, as kitty's font_size: the same text size in both.
            font = "${config.theme.fonts.mono}:size=${toString config.theme.fonts.size.normal}";
            pad = "${toString config.theme.padding}x${toString config.theme.padding} center";
          };
          scrollback.lines = 10000;
          mouse.hide-when-typing = "yes";
          cursor = {
            style = "beam";
            blink = "no";
          };
          # The compositor draws the frame (ShojiWM, Hyprland's borders).
          csd.preferred = "server";
          # The theme's dark palette ([colors] is the old name of this section).
          colors-dark = {
            alpha = "0.85";
            foreground = colour palette.foreground;
            background = colour palette.background;
            cursor = "${colour palette.background} ${colour palette.cursorColor}";
            selection-foreground = colour palette.background;
            selection-background = colour palette.selectionBackground;
            regular0 = colour palette.black;
            regular1 = colour palette.red;
            regular2 = colour palette.green;
            regular3 = colour palette.yellow;
            regular4 = colour palette.blue;
            regular5 = colour palette.purple;
            regular6 = colour palette.cyan;
            regular7 = colour palette.white;
            bright0 = colour palette.brightBlack;
            bright1 = colour palette.brightRed;
            bright2 = colour palette.brightGreen;
            bright3 = colour palette.brightYellow;
            bright4 = colour palette.brightBlue;
            bright5 = colour palette.brightPurple;
            bright6 = colour palette.brightCyan;
            bright7 = colour palette.brightWhite;
          };
        };
      };
    };
  };
}
