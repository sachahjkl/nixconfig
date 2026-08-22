{self, ...}: {
  flake.nixosModules.hyprlandWaybar = {
    config,
    lib,
    pkgs,
    ...
  }: let
    u = cp: builtins.fromJSON ("\"\\u" + cp + "\"");
    nerd = suffix: builtins.fromJSON ("\"\\uDB80\\uDC" + suffix + "\"");
    inherit (config) userName;
    rofiPkg = self.lib.mkRofi {
      inherit pkgs;
      theme = config.theme.rofiTheme;
    };
    powerMenuLauncher = config.powerMenu.package;
  in {
    hjem.users.${userName}.xdg.config.files = {
      "gsimplecal/config".text = ''
        show_calendar = 1
        show_timezones = 0
        show_week_numbers = 1
        mark_today = 1
        close_on_unfocus = 1
        mainwindow_decorated = 0
        mainwindow_keep_above = 1
        mainwindow_skip_taskbar = 1
        mainwindow_resizable = 0
        mainwindow_position = none
      '';
      "waybar/config".text = builtins.toJSON {
        layer = "bottom";
        position = "bottom";
        mode = "dock";
        exclusive = true;
        "gtk-layer-shell" = true;
        "margin-bottom" = -1;
        passthrough = false;
        height = 41;
        modules-left = ["custom/os_button" "hyprland/workspaces" "wlr/taskbar"];
        modules-right = [
          "custom/power-button"
          "mpris"
          "privacy"
          # "group/system"
          "tray"
          "wireplumber"
          "battery"
          "clock"
        ];
        "hyprland/workspaces" = {
          spacing = 16;
          on-scroll-up = "hyprctl dispatch workspace r+1";
          on-scroll-down = "hyprctl dispatch workspace r-1";
        };
        "custom/os_button" = {
          format = u "F17C";
          on-click = "${lib.getExe rofiPkg} -show drun -show-icons";
          tooltip = false;
        };
        "custom/power-button" = {
          format = u "F011";
          on-click = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch 'hl.dsp.exec_cmd(${builtins.toJSON (lib.getExe powerMenuLauncher)})'";
          tooltip-format = "Power menu";
        };
        "custom/system" = {
          format = u "F4BC";
          on-click = "${config.terminal.command} -e ${lib.getExe pkgs.btop}";
          tooltip-format = "System monitor";
        };
        "group/system" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 250;
            transition-left-to-right = false;
          };
          modules = ["custom/system" "cpu" "memory" "disk"];
        };
        cpu = {
          interval = 5;
          format = "${u "F2DB"} {usage}%";
          tooltip-format = "CPU load: {usage}%";
        };
        disk = {
          interval = 30;
          format = "${u "F0C7"} {percentage_used}%";
          path = "/";
          tooltip = true;
          unit = "GB";
          tooltip-format = "Available {free} of {total}";
        };
        memory = {
          interval = 10;
          format = "${u "F0E7"} {percentage}%";
          tooltip = true;
          tooltip-format = "RAM - {used:0.1f}GiB used";
        };
        "wlr/taskbar" = {
          format = "{icon} {title:.17}";
          icon-size = 28;
          spacing = 3;
          on-click-middle = "close";
          tooltip-format = "{title}";
          on-click = "activate";
        };
        tray = {
          icon-size = 18;
          spacing = 3;
        };
        clock = {
          format = "{:%H:%M  %a %d %b}";
          tooltip = false;
          on-click = lib.getExe pkgs.gsimplecal;
        };
        mpris = {
          format = "{status_icon}";
          format-paused = "{status_icon}";
          tooltip-format = "{player_icon} {dynamic}";
          dynamic-order = ["title" "artist"];
          dynamic-len = 32;
          status-icons = {
            playing = u "F04C";
            paused = u "F04B";
            stopped = u "F04B";
          };
          on-click = "${lib.getExe pkgs.playerctl} play-pause";
          on-click-middle = "${lib.getExe pkgs.playerctl} previous";
          on-click-right = "${lib.getExe pkgs.playerctl} next";
        };
        privacy = {
          icon-spacing = 5;
          icon-size = 16;
          transition-duration = 250;
          modules = [
            {
              type = "audio-in";
              tooltip = true;
            }
            {
              type = "screenshare";
              tooltip = true;
            }
          ];
        };
        battery = {
          states = {
            good = 95;
            warning = 30;
            critical = 20;
          };
          format = "{icon} {capacity}%";
          format-charging = "${u "F1E6"} {capacity}%";
          format-plugged = "${u "F1E6"} {capacity}%";
          format-alt = "{time} {icon}";
          format-icons = map nerd ["8E" "7A" "7B" "7C" "7D" "7E" "7F" "80" "81" "82" "79"];
        };
        wireplumber = {
          max-volume = 150;
          scroll-step = 5;
          format = "{icon} {volume}%";
          tooltip-format = "{node_name}\n{volume}%";
          format-muted = "${u "F026"} muted";
          format-icons.default = ["${u "F026"} " "${u "F027"} " "${u "F028"} "];
          on-click = lib.getExe pkgs.pwvucontrol;
          on-click-right = "${lib.getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };
      };

      "waybar/style.css".text = ''
        @define-color bg_main rgba(25, 25, 25, 0.65);
        @define-color bg_main_tooltip rgba(0, 0, 0, 0.7);
        @define-color bg_hover rgba(200, 200, 200, 0.3);
        @define-color bg_active rgba(100, 100, 100, 0.5);
        @define-color border_main rgba(255, 255, 255, 0.2);
        @define-color content_main white;
        @define-color content_inactive rgba(255, 255, 255, 0.25);
        * { text-shadow: none; box-shadow: none; border: none; border-radius: 0; font-family: "${config.theme.fonts.sans}", "Noto Sans"; font-weight: 600; font-size: 12.7px; }
        #cpu, #memory, #disk, #mpris, #battery, #wireplumber, #custom-system, #custom-power-button { font-family: "${config.theme.fonts.mono}", "${config.theme.fonts.sans}", "Noto Sans"; }
        window#waybar { background: @bg_main; border-top: 1px solid @border_main; color: @content_main; }
        tooltip { background: @bg_main_tooltip; border-radius: 5px; border-width: 1px; border-style: solid; border-color: @border_main; }
        tooltip label { color: @content_main; }
        #custom-power-button { min-width: 0; padding: 0 7px; }
        #custom-os_button { font-family: "${config.theme.fonts.mono}"; font-size: 24px; padding-left: 12px; padding-right: 20px; transition: all 0.25s cubic-bezier(0.165, 0.84, 0.44, 1); }
        #custom-os_button:hover { background: @bg_hover; color: @content_main; }
        #workspaces { color: transparent; margin-right: 1.5px; margin-left: 1.5px; }
        #workspaces button { padding: 3px; color: @content_inactive; transition: all 0.25s cubic-bezier(0.165, 0.84, 0.44, 1); }
        #workspaces button.active { color: @content_main; border-bottom: 3px solid white; }
        #workspaces button.urgent { background: rgba(255, 200, 0, 0.35); border-bottom: 3px dashed orange; color: orange; }
        #workspaces button:hover { background: @bg_hover; color: @content_main; }
        #taskbar button { min-width: 130px; border-bottom: 3px solid rgba(255, 255, 255, 0.3); margin-left: 2px; margin-right: 2px; padding-left: 8px; padding-right: 8px; color: white; transition: all 0.25s cubic-bezier(0.165, 0.84, 0.44, 1); }
        #taskbar button.active { border-bottom: 3px solid white; background: @bg_active; }
        #taskbar button:hover { border-bottom: 3px solid white; background: @bg_hover; color: @content_main; }
        #custom-system, #cpu, #disk, #memory { padding: 0 6px; transition: all 0.25s cubic-bezier(0.165, 0.84, 0.44, 1); }
        #custom-system:hover, #cpu:hover, #disk:hover, #memory:hover { background: @bg_hover; }
        #tray { margin-left: 5px; margin-right: 5px; }
        #tray > widget { transition: all 0.25s cubic-bezier(0.165, 0.84, 0.44, 1); }
        #tray > widget:hover { background: @bg_hover; }
        #tray > .needs-attention { background: rgba(255, 200, 0, 0.25); }
        #mpris, #privacy { min-width: 0; padding: 0; }
        #mpris.playing, #mpris.paused { padding: 0 7px; transition: all 0.25s cubic-bezier(0.165, 0.84, 0.44, 1); }
        #privacy-item, #wireplumber, #battery, #clock { padding: 0 7px; transition: all 0.25s cubic-bezier(0.165, 0.84, 0.44, 1); }
        #mpris.playing:hover, #mpris.paused:hover, #wireplumber:hover, #clock:hover, #custom-power-button:hover { background: @bg_hover; }
        #battery.warning { color: #ffcc66; }
        #battery.critical { color: #ff6699; border-bottom: 3px dashed #ff6699; }
      '';
    };

    systemd.user.services.waybar = {
      description = "Waybar status bar";
      wantedBy = ["graphical-session.target"];
      after = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      serviceConfig = {
        ExecStart = lib.getExe pkgs.waybar;
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
