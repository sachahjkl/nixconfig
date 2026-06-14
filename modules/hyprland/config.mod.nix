{self, ...}: {
  flake.nixosModules.hyprlandConfig = {
    config,
    lib,
    pkgs,
    ...
  }: let
    hyprCfg = config.preferences.hyprland;
    powerChoices = "lockscreen/logout/suspend/hibernate/shutdown/reboot";
    inherit (config) userName;
    rofiPkg = self.lib.mkRofi {
      inherit pkgs;
      theme = config.preferences.theme.rofiTheme;
    };
  in {
    options.preferences.hyprland = {
      laptopMode = {
        enable = lib.mkEnableOption "laptop-specific Hyprland power behavior";

        lockTimeoutSeconds = lib.mkOption {
          type = lib.types.int;
          default = 300;
          description = "Seconds before Hyprland locks the session when laptop mode is enabled.";
        };

        displayOffTimeoutSeconds = lib.mkOption {
          type = lib.types.int;
          default = 120;
          description = "Seconds before Hyprland turns displays off when laptop mode is enabled.";
        };

        suspendTimeoutSeconds = lib.mkOption {
          type = lib.types.int;
          default = 1800;
          description = "Seconds before Hyprland suspends the system when laptop mode is enabled.";
        };

        lidSwitchAction = lib.mkOption {
          type = lib.types.enum ["ignore" "lock" "suspend" "hibernate" "hybrid-sleep" "poweroff"];
          default = "suspend";
          description = "logind action to take when the laptop lid closes on battery.";
        };

        lidSwitchExternalPowerAction = lib.mkOption {
          type = lib.types.enum ["ignore" "lock" "suspend" "hibernate" "hybrid-sleep" "poweroff"];
          default = "ignore";
          description = "logind action to take when the laptop lid closes on AC power.";
        };

        lidSwitchDockedAction = lib.mkOption {
          type = lib.types.enum ["ignore" "lock" "suspend" "hibernate" "hybrid-sleep" "poweroff"];
          default = "ignore";
          description = "logind action to take when the laptop lid closes while docked.";
        };
      };

      display = {
        output = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Hyprland monitor output name for the primary monitor rule. Empty applies to the default monitor.";
        };

        mode = lib.mkOption {
          type = lib.types.str;
          default = "preferred";
          description = "Hyprland monitor mode for the primary monitor rule.";
        };

        scale = lib.mkOption {
          type = lib.types.number;
          default = 1.875;
          description = "Hyprland scale factor for the primary monitor rule.";
        };
      };

      numLock.defaultState = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Default Num Lock state in Hyprland. Use null to leave it unset, false to disable Num Lock, or true to enable it.";
      };

      waybar.temperature = {
        hwmonPath = lib.mkOption {
          type = lib.types.str;
          default = "/sys/devices/platform/coretemp.0/hwmon";
          description = "Absolute hwmon directory Waybar should read for temperatures.";
        };

        inputFilename = lib.mkOption {
          type = lib.types.str;
          default = "temp2_input";
          description = "Waybar temperature input filename inside the configured hwmon directory.";
        };
      };
    };

    config = lib.mkMerge [
      {
        environment.sessionVariables = {
          XCURSOR_THEME = config.preferences.theme.cursor;
          XCURSOR_SIZE = toString config.preferences.theme.cursorSize;
          HYPRCURSOR_SIZE = toString config.preferences.theme.cursorSize;
          QT_QPA_PLATFORM = "wayland";
          QT_QPA_PLATFORMTHEME = "qt5ct";
          QT_STYLE_OVERRIDE = "kvantum";
          NIXOS_OZONE_WL = "1";
          QT_SCALE_FACTOR = "1";
        };

        hjem.users.${userName}.xdg.config.files = {
          "hypr/hyprland.lua".text = ''
            local terminal = "uwsm app -- kitty"
            local fileManager = "uwsm app -- thunar"
            local menu = "uwsm app -- ${lib.getExe rofiPkg} -show drun -show-icons -run-command \"uwsm app -- {cmd}\""
            local mainMod = "SUPER"

            local satty_args = "--copy-command wl-copy -o \"$HOME/Pictures/Screenshots/%Y%m%d_%H%M%S.png\" --actions-on-enter save-to-clipboard,save-to-file,exit --actions-on-right-click save-to-clipboard,save-to-file,exit --floating-hack --no-window-decoration --fullscreen current-screen"

            hl.monitor({
                output   = ${builtins.toJSON hyprCfg.display.output},
                mode     = ${builtins.toJSON hyprCfg.display.mode},
                position = "auto",
                scale    = ${toString hyprCfg.display.scale},
            })

            hl.on("hyprland.start", function()
                hl.exec_cmd("uwsm app -- nm-applet")
                hl.exec_cmd("uwsm app -- thunar --daemon")
                hl.exec_cmd("uwsm app -- udiskie")
                hl.exec_cmd("uwsm app -- copyq --start-server")
                hl.exec_cmd("dbus-update-activation-environment --systemd --all")
                hl.exec_cmd("waybar")
                hl.exec_cmd("hyprpaper")
                hl.exec_cmd("hypridle")
                hl.exec_cmd("[workspace special:magic silent; float; size 1200 1000; move 80 80] " .. terminal .. " --title Scratchpad")
            end)

            hl.config({
                general = {
                    gaps_in  = 5,
                    gaps_out = 5,
                    border_size = 2,
                    col = {
                        active_border   = 0xeeffffff,
                        inactive_border = 0xaa595959,
                    },
                    resize_on_border = true,
                    allow_tearing    = false,
                    layout           = "master",
                },
                decoration = {
                    rounding       = 0,
                    active_opacity   = 1.0,
                    inactive_opacity = 1.0,
                    shadow = {
                        enabled      = true,
                        range        = 4,
                        render_power = 3,
                        color        = 0xee1a1a1a,
                    },
                    blur = {
                        enabled  = true,
                        size     = 3,
                        passes   = 3,
                        vibrancy = 0.4,
                    },
                },
                animations = {
                    enabled = false,
                },
                misc = {
                    force_default_wallpaper = -1,
                    disable_hyprland_logo   = true,
                    enable_swallow          = true,
                },
                ecosystem = {
                    no_update_news = true,
                },
                input = {
                kb_layout        = "fr",
                repeat_delay     = 200,
                numlock_by_default = ${
              if hyprCfg.numLock.defaultState == null
              then "nil"
              else if hyprCfg.numLock.defaultState
              then "true"
              else "false"
            },
                    follow_mouse     = 1,
                    sensitivity      = 0,
                    accel_profile    = "flat",
                    touchpad = {
                        natural_scroll = false,
                    },
                },
                binds = {
                    scroll_event_delay = 0,
                },
                dwindle = {
                    preserve_split = true,
                },
                master = {
                    new_status = "master",
                },
            })

            hl.window_rule({
                match = { class = "com.github.hluk.copyq" },
                float = true,
            })
            hl.window_rule({
                match = { class = "(satty|org.satty.Satty)" },
                float = true,
            })

            hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
            hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
            hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
            hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
            hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

            hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
            hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
            hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, bezier = "easeOutQuint" })
            hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
            hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
            hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
            hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
            hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
            hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
            hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
            hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
            hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
            hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
            hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
            hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
            hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })

            hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
            hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
            hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen())
            hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("pidof hyprlock || ${lib.getExe pkgs.hyprlock}"))
            hl.bind("PRINT", hl.dsp.exec_cmd("grim -g \"$(slurp -o)\" - | satty -f - " .. satty_args))
            hl.bind("CTRL + PRINT", hl.dsp.exec_cmd("grim -g \"$(slurp -d)\" - | satty -f - " .. satty_args))
            hl.bind("CTRL + SHIFT + PRINT", hl.dsp.exec_cmd("grim -g \"$(slurp -d)\" - | satty -f - " .. satty_args))
            hl.bind("SUPER + V", hl.dsp.exec_cmd("copyq menu"))
            hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("${lib.getExe rofiPkg} -show power-menu -modi \"power-menu:rofi-power-menu --choices=${powerChoices}\""))
            hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
            hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))
            hl.bind("CTRL + SHIFT + ugrave", hl.dsp.exec_cmd("copyq toggle"))
            hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
            hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
            hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
            hl.bind("ALT + Tab", hl.dsp.focus({ workspace = "e+1" }))
            hl.bind("ALT + SHIFT + Tab", hl.dsp.focus({ workspace = "e-1" }))

            hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
            hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
            hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
            hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

            hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
            hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
            hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
            hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

            hl.bind(mainMod .. " + CONTROL + right", hl.dsp.window.resize({ x = 40,  y = 0 }),   { repeating = true })
            hl.bind(mainMod .. " + CONTROL + left",  hl.dsp.window.resize({ x = -40, y = 0 }),   { repeating = true })
            hl.bind(mainMod .. " + CONTROL + up",    hl.dsp.window.resize({ x = 0,   y = -40 }), { repeating = true })
            hl.bind(mainMod .. " + CONTROL + down",  hl.dsp.window.resize({ x = 0,   y = 40 }),  { repeating = true })

            hl.bind(mainMod .. " + ampersand", hl.dsp.focus({ workspace = 1 }))
            hl.bind(mainMod .. " + eacute",    hl.dsp.focus({ workspace = 2 }))
            hl.bind(mainMod .. " + quotedbl",  hl.dsp.focus({ workspace = 3 }))
            hl.bind(mainMod .. " + apostrophe",hl.dsp.focus({ workspace = 4 }))
            hl.bind(mainMod .. " + parenleft", hl.dsp.focus({ workspace = 5 }))
            hl.bind(mainMod .. " + minus",     hl.dsp.focus({ workspace = 6 }))
            hl.bind(mainMod .. " + egrave",    hl.dsp.focus({ workspace = 7 }))
            hl.bind(mainMod .. " + underscore",hl.dsp.focus({ workspace = 8 }))
            hl.bind(mainMod .. " + ccedilla",  hl.dsp.focus({ workspace = 9 }))
            hl.bind(mainMod .. " + agrave",    hl.dsp.focus({ workspace = 10 }))

            hl.bind(mainMod .. " + SHIFT + ampersand", hl.dsp.window.move({ workspace = 1 }))
            hl.bind(mainMod .. " + SHIFT + eacute",    hl.dsp.window.move({ workspace = 2 }))
            hl.bind(mainMod .. " + SHIFT + quotedbl",  hl.dsp.window.move({ workspace = 3 }))
            hl.bind(mainMod .. " + SHIFT + apostrophe",hl.dsp.window.move({ workspace = 4 }))
            hl.bind(mainMod .. " + SHIFT + parenleft", hl.dsp.window.move({ workspace = 5 }))
            hl.bind(mainMod .. " + SHIFT + egrave",    hl.dsp.window.move({ workspace = 6 }))
            hl.bind(mainMod .. " + SHIFT + minus",     hl.dsp.window.move({ workspace = 7 }))
            hl.bind(mainMod .. " + SHIFT + underscore",hl.dsp.window.move({ workspace = 8 }))
            hl.bind(mainMod .. " + SHIFT + ccedilla",  hl.dsp.window.move({ workspace = 9 }))
            hl.bind(mainMod .. " + SHIFT + agrave",    hl.dsp.window.move({ workspace = 10 }))

            hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
            hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

            hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
            hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

            local MAX_ZOOM = 4
            local MIN_ZOOM = 1
            local function zoom(offset)
                local current = hl.get_config("cursor.zoom_factor")
                current = current + offset
                current = math.max(MIN_ZOOM, math.min(MAX_ZOOM, current))
                hl.config({ cursor = { zoom_factor = current } })
            end
            hl.bind(mainMod .. " + SHIFT + mouse_up",   function() zoom(-0.5) end)
            hl.bind(mainMod .. " + SHIFT + mouse_down", function() zoom(0.5) end)

            hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
            hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

            hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),     { locked = true, repeating = true })
            hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),     { locked = true, repeating = true })
            hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),    { locked = true, repeating = true })
            hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),  { locked = true, repeating = true })
            hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl s 10%+"),                          { locked = true, repeating = true })
            hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl s 10%-"),                          { locked = true, repeating = true })

            hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
            hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
            hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
            hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
          '';

          "hypr/hyprpaper.conf".text = ''
            wallpaper {
                monitor =
                path = ${config.assets.wallpaper}
                fit_mode = cover
            }
            splash = false
          '';
        };
      }
      (lib.mkIf hyprCfg.laptopMode.enable {
        services = {
          logind.settings.Login = {
            HandleLidSwitch = hyprCfg.laptopMode.lidSwitchAction;
            HandleLidSwitchExternalPower = hyprCfg.laptopMode.lidSwitchExternalPowerAction;
            HandleLidSwitchDocked = hyprCfg.laptopMode.lidSwitchDockedAction;
          };

          power-profiles-daemon.enable = true;
          upower.enable = true;
        };
      })
    ];
  };
}
