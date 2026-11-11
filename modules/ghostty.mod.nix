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
    # Under ShojiWM the compositor draws Ghostty's frame and its tabs: each
    # tab is a window of one group (shojiwm-desktop, src/groups.ts).
    shojiwmTabs = lib.attrByPath ["shojiwm" "enable"] false config;
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
          settings =
            {
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
              "window-titlebar-background" = terminalTheme.background;
              "window-titlebar-foreground" = terminalTheme.foreground;
              "window-title-font-family" = config.theme.fonts.sans;
              "window-padding-x" = config.theme.padding;
              "window-padding-y" = config.theme.padding;
              "window-save-state" = "always";
              "window-inherit-working-directory" = true;
              "tab-inherit-working-directory" = true;
              "split-inherit-working-directory" = true;
              "notify-on-command-finish" = "unfocused";
              "notify-on-command-finish-action" = "no-bell,notify";
              "gtk-titlebar" = !shojiwmTabs;
              "gtk-titlebar-style" = "tabs";
              "gtk-tabs-location" = "top";
              "gtk-wide-tabs" = false;
              "window-show-tab-bar" =
                if shojiwmTabs
                then "never"
                else "always";
              "gtk-single-instance" = true;
              # A launch from a .desktop file or a shell passes this on to the
              # daemon: false made it open no window. The daemon's own unit
              # starts it windowless whatever this says.
              "initial-window" = true;
              "quit-after-last-window-closed" = false;
            }
            // lib.optionalAttrs shojiwmTabs {
              # The compositor's frame, not Ghostty's title bar.
              "window-decoration" = "server";
              # A new tab is a new window: ShojiWM opens it as a tab of the
              # Ghostty window used last.
              keybind = ["ctrl+shift+t=new_window"];
            };
        };
      };
    };
  };
}
