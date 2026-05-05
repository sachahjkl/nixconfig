{ config, lib, ... }:

let
  isHypr = lib.elem config.desktop.environment [ "hyprland" "both" ];
  userName = config.sacha.userName;
in
lib.mkIf isHypr {
  home-manager.users.${userName}.xdg.configFile = {
    "hypr/hypridle.conf".text = ''
      general {
        lock_cmd = pidof hyprlock || hyprlock
        before_sleep_cmd = pidof hyprlock || hyprlock
        after_sleep_cmd = hyprctl dispatch dpms on
      }

      listener {
        timeout = 300
        on-timeout = pidof hyprlock || hyprlock
      }
    '';

    "hypr/hyprlock.conf".text = ''
      background {
        path = ${config.sacha.assets.wallpaper}
        blur_passes = 3
        noise = 0.05
      }

      general {
        no_fade_in = true
        no_fade_out = true
        hide_cursor = false
        disable_loading_bar = true
        grace = 0
      }

      input-field {
        size = 20%, 5%
        outline_thickness = 3
        inner_color = rgba(0, 0, 0, 1)
        outer_color = rgba(255, 255, 255, 1)
        check_color = rgba(59, 130, 246, 1)
        fail_color = rgba(220, 38, 38, 1)
        font_color = rgb(255, 255, 255)
        fade_on_empty = false
        rounding = 0
        position = 0, -40
        halign = center
        valign = center
      }

      label {
        shadow_passes = 1
        text = cmd[update:1000] echo "$(date +"%A, %B %d")"
        color = rgb(255,255,255)
        font_size = 22
        font_family = sans-serif
        position = 0, 300
        halign = center
        valign = center
      }

      label {
        shadow_passes = 1
        text = cmd[update:1000] echo "$(date +"%-I:%M")"
        color = rgb(255,255,255)
        font_size = 95
        font_family = sans-serif
        position = 0, 200
        halign = center
        valign = center
      }

      image {
        shadow_passes = 1
        path = ${config.sacha.assets.faceIcon}
        size = 300
        border_size = 2
        border_color = black
        position = 0, 500
        halign = center
        valign = center
      }

      label {
        shadow_passes = 1
        text = Nah, you out, $USER
        color = rgba(200, 200, 200, 1.0)
        font_size = 25
        font_family = sans-serif
        position = 0, 80
        halign = center
        valign = center
      }
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
}
