{ self, ... }:

{
  flake.nixosModules.hyprlandConfig = { config, lib, pkgs, ... }:
    let
      desktopEnvironment = lib.attrByPath [ "desktop" "environment" ] null config;
      isHypr = lib.elem desktopEnvironment [ "hyprland" "both" "all" ];
      userName = config.sacha.userName;
      selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
      rofiPkg = self.lib.mkRofi {
        inherit pkgs;
        theme = config.sacha.theme.rofiTheme;
      };
      hyprlockPkg = self.lib.mkHyprlock {
        inherit pkgs;
        wallpaper = config.sacha.assets.wallpaper;
        faceIcon = config.sacha.assets.faceIcon;
      };
    in
    lib.mkIf isHypr {
      environment.sessionVariables = {
        XCURSOR_SIZE = toString config.sacha.theme.cursorSize;
        HYPRCURSOR_SIZE = toString config.sacha.theme.cursorSize;
        QT_QPA_PLATFORM = "wayland";
        QT_QPA_PLATFORMTHEME = "qt5ct";
        TERMINAL = "kitty";
        NIXOS_OZONE_WL = "1";
        QT_SCALE_FACTOR = "1";
      };

      hjem.users.${userName}.xdg.config.files = {
        "hypr/hyprland.conf".text = ''
          $terminal = uwsm app -- kitty
          $fileManager = uwsm app -- thunar
          $menu = uwsm app -- ${lib.getExe rofiPkg} -show drun -show-icons -run-command "uwsm app -- {cmd}"
          $mainMod = SUPER

          monitor = ,preferred,auto,1.875

          exec-once = uwsm app -- nm-applet
          exec-once = uwsm app -- thunar --daemon
          exec-once = uwsm app -- udiskie
          exec-once = uwsm app -- copyq --start-server
          exec-once = dbus-update-activation-environment --systemd --all
          exec-once = waybar
          exec-once = hyprpaper
          exec-once = hypridle
          exec-once = [workspace special:magic silent; float; size 1200 1000; move 80 80] $terminal --title Scratchpad

          general {
            gaps_in = 5
            gaps_out = 5
            border_size = 2
            col.active_border = 0xeeffffff
            col.inactive_border = 0xaa595959
            resize_on_border = 1
            allow_tearing = 0
            layout = master
          }

          decoration {
            rounding = 0
            active_opacity = 1.0
            inactive_opacity = 1.0

            shadow {
              enabled = 1
              range = 4
              render_power = 3
              color = 0xee1a1a1a
            }

            blur {
              enabled = 1
              size = 3
              passes = 3
              vibrancy = 0.4
            }
          }

          animations {
            enabled = 0
          }

          dwindle {
            pseudotile = 1
            preserve_split = 1
          }

          master {
            new_status = master
          }

          misc {
            force_default_wallpaper = -1
            disable_hyprland_logo = 1
            enable_swallow = 1
          }

          ecosystem {
            no_update_news = 1
          }

          input {
            kb_layout = fr
            repeat_delay = 200
            numlock_by_default = 1
            follow_mouse = 1
            sensitivity = 0
            accel_profile = flat

            touchpad {
              natural_scroll = 0
            }
          }

          binds {
            scroll_event_delay = 0
          }

          windowrule = match:class (com.github.hluk.copyq), float on
          windowrule = match:class (satty|org.satty.Satty), float on

          bezier = easeOutQuint,0.23,1,0.32,1
          bezier = easeInOutCubic,0.65,0.05,0.36,1
          bezier = linear,0,0,1,1
          bezier = almostLinear,0.5,0.5,0.75,1.0
          bezier = quick,0.15,0,0.1,1
          animation = global, 0.25, 10, default
          animation = border, 0.25, 5.39, easeOutQuint
          animation = windows, 0.25, 4.79, easeOutQuint
          animation = windowsIn, 0.25, 4.1, easeOutQuint, popin 87%
          animation = windowsOut, 0.25, 1.49, linear, popin 87%
          animation = fadeIn, 0.25, 1.73, almostLinear
          animation = fadeOut, 0.25, 1.46, almostLinear
          animation = fade, 0.25, 3.03, quick
          animation = layers, 0.25, 3.81, easeOutQuint
          animation = layersIn, 0.25, 4, easeOutQuint, fade
          animation = layersOut, 0.25, 1.5, linear, fade
          animation = fadeLayersIn, 0.25, 1.79, almostLinear
          animation = fadeLayersOut, 0.25, 1.39, almostLinear
          animation = workspaces, 0.25, 1.94, almostLinear, fade
          animation = workspacesIn, 0.25, 1.21, almostLinear, fade
          animation = workspacesOut, 0.25, 1.94, almostLinear, fade

          bind = $mainMod, RETURN, exec, $terminal
          bind = $mainMod SHIFT, Q, killactive
          bind = $mainMod SHIFT, F, fullscreen
          bind = $mainMod, L, exec, pidof hyprlock || ${lib.getExe hyprlockPkg}
          bind = CTRL, PRINT, exec, hypr-screenshot window
          bind = , PRINT, exec, hypr-screenshot output
          bind = CTRL SHIFT, PRINT, exec, hypr-screenshot region
          bind = SUPER, V, exec, copyq menu
            bind = $mainMod SHIFT, E, exec, ${lib.getExe rofiPkg} -show power-menu -modi "power-menu:rofi-power-menu --choices=lockscreen/logout/shutdown/reboot"
          bind = $mainMod, E, exec, $fileManager
          bind = $mainMod SHIFT, SPACE, togglefloating
          bind = CTRL SHIFT, ugrave, exec, copyq toggle
          bind = $mainMod, D, exec, $menu
          bind = $mainMod, P, pseudo
          bind = $mainMod, J, layoutmsg, togglesplit
          bind = ALT, Tab, workspace, e+1
          bind = ALT SHIFT, Tab, workspace, e-1
          bind = $mainMod, left, movefocus, l
          bind = $mainMod, right, movefocus, r
          bind = $mainMod, up, movefocus, u
          bind = $mainMod, down, movefocus, d
          bind = $mainMod SHIFT, left, movewindow, l
          bind = $mainMod SHIFT, right, movewindow, r
          bind = $mainMod SHIFT, up, movewindow, u
          bind = $mainMod SHIFT, down, movewindow, d
          binde = $mainMod CONTROL, right, resizeactive, 40 0
          binde = $mainMod CONTROL, left, resizeactive, -40 0
          binde = $mainMod CONTROL, up, resizeactive, 0 -40
          binde = $mainMod CONTROL, down, resizeactive, 0 40
          bind = $mainMod, ampersand, workspace, 1
          bind = $mainMod, eacute, workspace, 2
          bind = $mainMod, quotedbl, workspace, 3
          bind = $mainMod, apostrophe, workspace, 4
          bind = $mainMod, parenleft, workspace, 5
          bind = $mainMod, minus, workspace, 6
          bind = $mainMod, egrave, workspace, 7
          bind = $mainMod, underscore, workspace, 8
          bind = $mainMod, ccedilla, workspace, 9
          bind = $mainMod, agrave, workspace, 10
          bind = $mainMod SHIFT, ampersand, movetoworkspace, 1
          bind = $mainMod SHIFT, eacute, movetoworkspace, 2
          bind = $mainMod SHIFT, quotedbl, movetoworkspace, 3
          bind = $mainMod SHIFT, apostrophe, movetoworkspace, 4
          bind = $mainMod SHIFT, parenleft, movetoworkspace, 5
          bind = $mainMod SHIFT, egrave, movetoworkspace, 6
          bind = $mainMod SHIFT, minus, movetoworkspace, 7
          bind = $mainMod SHIFT, underscore, movetoworkspace, 8
          bind = $mainMod SHIFT, ccedilla, movetoworkspace, 9
          bind = $mainMod SHIFT, agrave, movetoworkspace, 10
          bind = $mainMod, S, togglespecialworkspace, magic
          bind = $mainMod SHIFT, S, movetoworkspace, special:magic
          bind = $mainMod, mouse_down, workspace, e+1
          bind = $mainMod, mouse_up, workspace, e-1
          bindm = $mainMod, mouse:272, movewindow
          bindm = $mainMod, mouse:273, resizewindow
          bindel = ,XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
          bindel = ,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
          bindel = ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
          bindel = ,XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
          bindel = ,XF86MonBrightnessUp, exec, brightnessctl s 10%+
          bindel = ,XF86MonBrightnessDown, exec, brightnessctl s 10%-
          bindl = , XF86AudioNext, exec, playerctl next
          bindl = , XF86AudioPause, exec, playerctl play-pause
          bindl = , XF86AudioPlay, exec, playerctl play-pause
          bindl = , XF86AudioPrev, exec, playerctl previous
        '';

        "hypr/hyprpaper.conf".text = ''
          wallpaper {
              monitor =
              path = ${config.sacha.assets.wallpaper}
              fit_mode = cover
          }
          splash = false
        '';

      };
    };
}
