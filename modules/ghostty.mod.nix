_: {
  flake.nixosModules.ghostty = {
    config,
    lib,
    pkgs,
    ...
  }: let
    terminalPreferences = lib.attrByPath ["terminal"] {} config;
    enabled = lib.attrByPath ["ghostty" "enable"] false terminalPreferences || lib.attrByPath ["default"] null terminalPreferences == "ghostty";
    inherit (config) userName;
    terminalTheme = lib.attrByPath ["ghostty" "theme"] config.theme.terminalPalette terminalPreferences;
  in {
    config = lib.mkIf enabled {
      environment = {
        systemPackages = [pkgs.ghostty];
      };

      services.dbus.packages = [pkgs.ghostty];
      systemd.packages = [pkgs.ghostty];
      # The daemon, started with every session as the unit's [Install] section
      # asks (NixOS does not apply it). Its unit passes --initial-window=false,
      # so it starts with no window; each launch then opens one.
      # Declared on the target, not on the service: a service option makes
      # NixOS write an override with its own minimal PATH, which Ghostty
      # passes on to every shell it opens.
      systemd.user.targets.graphical-session.wants = ["app-com.mitchellh.ghostty.service"];

      hjem.users.${userName} = {
        rum.programs.ghostty = {
          enable = true;
          package = null;
          settings = {
            "font-family" = config.theme.fonts.mono;
            # Two steps (points) under the shared size: Ghostty's cells read
            # larger than kitty's at the same size.
            "font-size" = config.theme.fonts.size.normal - 2;
            "shell-integration" = "detect";
            "cursor-click-to-move" = true;
            "mouse-hide-while-typing" = true;
            "mouse-scroll-multiplier" = "precision:1,discrete:1";
            scrollbar = "system";
            inherit (terminalTheme) foreground;
            inherit (terminalTheme) background;
            "cursor-color" = terminalTheme.cursorColor;
            "selection-background" = terminalTheme.selectionBackground;
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
            "window-padding-x" = config.theme.padding;
            "window-padding-y" = config.theme.padding;
            "window-save-state" = "always";
            "window-inherit-working-directory" = true;
            "tab-inherit-working-directory" = true;
            "split-inherit-working-directory" = true;
            "notify-on-command-finish" = "unfocused";
            "notify-on-command-finish-action" = "no-bell,notify";
            # The compositor's frame (ShojiWM's Aero frame), not a GTK header
            # bar: one title bar and one close button. The tab bar shows
            # from two tabs on.
            "window-decoration" = "server";
            "gtk-titlebar" = false;
            "gtk-tabs-location" = "top";
            "gtk-wide-tabs" = false;
            "window-show-tab-bar" = "auto";
            "gtk-single-instance" = true;
            # A launch from a .desktop file or a shell passes this on to the
            # daemon: false made it open no window. The daemon's own unit
            # starts it windowless whatever this says.
            "initial-window" = true;
            "quit-after-last-window-closed" = false;
          };
        };
      };
    };
  };
}
