{self, ...}: {
  flake.nixosModules.ghostty = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.features.ghostty;
    defaultTerminal = config.preferences.terminal.id == "ghostty";
    inherit (config) userName;
    terminalTheme = self.lib.terminalTheme;
    ghosttyDefaultDesktop = pkgs.makeDesktopItem {
      name = "ghostty-default";
      desktopName = "Ghostty";
      comment = "Open a new Ghostty window";
      exec = "ghostty +new-window";
      icon = "com.mitchellh.ghostty";
      terminal = false;
      categories = ["System" "TerminalEmulator"];
      startupNotify = true;
    };
  in {
    options.features.ghostty = {
      enable = lib.mkEnableOption "Ghostty terminal emulator";
      fontSize = lib.mkOption {
        type = lib.types.number;
        default = 14;
        description = "Ghostty terminal font size.";
      };
    };

    config = lib.mkIf cfg.enable {
      environment = {
        systemPackages =
          [pkgs.ghostty]
          ++ lib.optionals defaultTerminal [ghosttyDefaultDesktop];
      };

      services.dbus.packages = [pkgs.ghostty];
      systemd.packages = [pkgs.ghostty];

      hjem.users.${userName} = {
        rum.programs.ghostty = {
          enable = true;
          package = null;
          settings = {
            "font-family" = config.preferences.theme.fonts.mono;
            "font-size" = cfg.fontSize;
            "shell-integration" = "detect";
            "cursor-click-to-move" = true;
            "mouse-hide-while-typing" = true;
            inherit (terminalTheme) foreground;
            inherit (terminalTheme) background;
            "cursor-color" = terminalTheme.cursorColor;
            "selection-background" = terminalTheme.selectionBackground;
            "background-opacity" = 0.9;
            "background-opacity-cells" = true;
            "background-blur" = true;
            palette = [
              "0=${terminalTheme.black}"
              "1=${terminalTheme.red}"
              "2=${terminalTheme.green}"
              "3=${terminalTheme.yellow}"
              "4=${terminalTheme.blue}"
              "5=${terminalTheme.purple}"
              "6=${terminalTheme.cyan}"
              "7=${terminalTheme.white}"
              "8=${terminalTheme.brightBlack}"
              "9=${terminalTheme.brightRed}"
              "10=${terminalTheme.brightGreen}"
              "11=${terminalTheme.brightYellow}"
              "12=${terminalTheme.brightBlue}"
              "13=${terminalTheme.brightPurple}"
              "14=${terminalTheme.brightCyan}"
              "15=${terminalTheme.brightWhite}"
            ];
            "window-theme" = "ghostty";
            "window-titlebar-background" = terminalTheme.background;
            "window-titlebar-foreground" = terminalTheme.foreground;
            "window-title-font-family" = config.preferences.theme.fonts.sans;
            "window-padding-x" = 8;
            "window-padding-y" = 6;
            "window-save-state" = "always";
            "window-inherit-working-directory" = true;
            "tab-inherit-working-directory" = true;
            "split-inherit-working-directory" = true;
            "notify-on-command-finish" = "unfocused";
            "notify-on-command-finish-action" = "no-bell,notify";
            "gtk-titlebar" = true;
            "gtk-titlebar-style" = "tabs";
            "gtk-tabs-location" = "top";
            "gtk-wide-tabs" = false;
            "window-show-tab-bar" = "always";
            "gtk-single-instance" = true;
            "initial-window" = false;
            "quit-after-last-window-closed" = false;
          };
        };
      };
    };
  };
}
