_: {
  flake.nixosModules.hyprlandLock = {
    config,
    lib,
    pkgs,
    ...
  }: let
    hyprCfg =
      lib.attrByPath ["preferences" "hyprland"]
      {
        display.scale = 1.875;
        laptopMode = {
          enable = false;
          lockTimeoutSeconds = 300;
          displayOffTimeoutSeconds = 120;
          suspendTimeoutSeconds = 1800;
        };
      }
      config;
    scaleValue = hyprCfg.display.scale;
    desktopReferenceScale = 1.875;
    lockUiScale = scaleValue / desktopReferenceScale;
    scalePx = value: builtins.floor ((value * lockUiScale) + 0.5);
    laptopCfg =
      lib.attrByPath ["preferences" "hyprland" "laptopMode"]
      {
        enable = false;
        lockTimeoutSeconds = 300;
        displayOffTimeoutSeconds = 120;
        suspendTimeoutSeconds = 1800;
      }
      config;
    lockCmd = "pidof hyprlock || ${lib.getExe pkgs.hyprlock}";
    inherit (config) userName;
  in {
    hjem.users.${userName}.rum.programs = {
      hyprlock = {
        enable = true;
        package = null;
        settings = {
          background = [
            {
              path = toString config.assets.wallpaper;
              blur_passes = 3;
              noise = 0.05;
            }
          ];
          general = {
            no_fade_in = true;
            no_fade_out = true;
            hide_cursor = false;
            disable_loading_bar = true;
            grace = 0;
          };
          "input-field" = [
            {
              size = "20%, 5%";
              outline_thickness = scalePx 3;
              inner_color = "rgba(0, 0, 0, 1)";
              outer_color = "rgba(255, 255, 255, 1)";
              check_color = "rgba(59, 130, 246, 1)";
              fail_color = "rgba(220, 38, 38, 1)";
              font_color = "rgb(255, 255, 255)";
              fade_on_empty = false;
              rounding = 0;
              position = "0, -${toString (scalePx 40)}";
              halign = "center";
              valign = "center";
            }
          ];
          label = [
            {
              shadow_passes = 1;
              text = "cmd[update:1000] echo \"$(date +\"%A, %B %d\")\"";
              color = "rgb(255,255,255)";
              font_size = scalePx 22;
              font_family = "sans-serif";
              position = "0, ${toString (scalePx 300)}";
              halign = "center";
              valign = "center";
            }
            {
              shadow_passes = 1;
              text = "cmd[update:1000] echo \"$(date +\"%-I:%M\")\"";
              color = "rgb(255,255,255)";
              font_size = scalePx 95;
              font_family = "sans-serif";
              position = "0, ${toString (scalePx 200)}";
              halign = "center";
              valign = "center";
            }
            {
              shadow_passes = 1;
              text = "Nah, you out, $USER";
              color = "rgba(200, 200, 200, 1.0)";
              font_size = scalePx 25;
              font_family = "sans-serif";
              position = "0, ${toString (scalePx 80)}";
              halign = "center";
              valign = "center";
            }
          ];
          image = [
            {
              shadow_passes = 1;
              path = toString config.assets.faceIcon;
              size = scalePx 300;
              border_size = scalePx 2;
              border_color = "black";
              position = "0, ${toString (scalePx 500)}";
              halign = "center";
              valign = "center";
            }
          ];
        };
      };

      hypridle = {
        enable = true;
        package = null;
        settings = {
          general = {
            lock_cmd = lockCmd;
            before_sleep_cmd = lockCmd;
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };
          listener =
            if laptopCfg.enable
            then [
              {
                timeout = laptopCfg.lockTimeoutSeconds;
                on-timeout = lockCmd;
              }
              {
                timeout = laptopCfg.displayOffTimeoutSeconds;
                on-timeout = "hyprctl dispatch dpms off";
                on-resume = "hyprctl dispatch dpms on";
              }
              {
                timeout = laptopCfg.suspendTimeoutSeconds;
                on-timeout = "systemctl suspend";
              }
            ]
            else [
              {
                timeout = 300;
                on-timeout = lockCmd;
              }
              {
                timeout = 120;
                on-timeout = "hyprctl dispatch dpms off";
                on-resume = "hyprctl dispatch dpms on";
              }
            ];
        };
      };
    };
  };
}
