{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.shojiwm = {
    config,
    lib,
    pkgs,
    ...
  }: let
    configHome = "${config.homeDirectory}/.config/shojiwm";
    hokum = inputs.hokum.packages.${pkgs.stdenv.hostPlatform.system}.default;
    # Hokum's package also carries a D-Bus activation file for
    # org.freedesktop.Notifications, which would race dunst's in Hyprland:
    # only the command and the launcher are installed.
    hokumCommand = pkgs.runCommand "hokum-command" {} ''
      mkdir -p "$out/bin" "$out/share/applications"
      ln -s ${lib.getExe hokum} "$out/bin/hokum"
      ln -s ${hokum}/share/applications/hokum.desktop "$out/share/applications/hokum.desktop"
    '';
    # A checkout is linked as is: its files change without a rebuild.
    configSource =
      if config.shojiwm.checkout == null
      then inputs.shojiwm-win7.packages.${pkgs.stdenv.hostPlatform.system}.default
      else config.shojiwm.checkout;

    # The Hyprland monitor rules, `name,mode,position,scale` separated by
    # `;`, read by src/index.tsx of shojiwm-win7. The value holds no quotes:
    # the session environment files do not escape them.
    monitors = builtins.filter (monitor: monitor.output != "") (lib.attrByPath ["hyprland" "display" "monitors"] [] config);
    outputRules = lib.concatMapStringsSep ";" (monitor: "${monitor.output},${monitor.mode},${monitor.position},${toString monitor.scale}") monitors;

    # The log-on screen: shojiwm-win7's greeter.qml in a Hyprland of its
    # own, with the same screens as the sessions. It always comes from the
    # package: the greeter account cannot read a checkout in a home.
    greeterShell = "${inputs.shojiwm-win7.packages.${pkgs.stdenv.hostPlatform.system}.default}/shell/greeter.qml";
    greeterSession = pkgs.writeShellScript "shojiwm-win7-greeter" ''
      export SHOJIWM_GREETER_USER=${lib.escapeShellArg config.userName}
      export SHOJIWM_GREETER_SESSIONS=${config.services.displayManager.sessionData.desktops}/share/wayland-sessions
      export SHOJIWM_GREETER_DEFAULT_SESSION=${lib.escapeShellArg config.shojiwm.greeter.defaultSession}
      export SHOJIWM_WIN7_PRIMARY_SCREEN=${lib.escapeShellArg config.shojiwm.greeter.mainScreen}
      ${lib.getExe pkgs.quickshell} -p ${greeterShell}
      # The session starts once the compositor has left the screen. The
      # configuration is Lua: dispatch takes a Lua call.
      ${pkgs.hyprland}/bin/hyprctl dispatch 'hl.dsp.exit()'
    '';
    greeterHyprland = pkgs.writeText "shojiwm-win7-greeter.lua" ''
      ${lib.concatMapStrings (monitor: ''
          hl.monitor({
              output   = ${builtins.toJSON monitor.output},
              mode     = ${builtins.toJSON monitor.mode},
              position = ${builtins.toJSON monitor.position},
              scale    = ${toString monitor.scale},
          })
        '')
        monitors}
      hl.on("hyprland.start", function()
          hl.exec_cmd("${greeterSession}")
      end)

      hl.config({
          misc = {
              disable_hyprland_logo   = true,
              force_default_wallpaper = 0,
          },
          animations = {
              enabled = false,
          },
          ecosystem = {
              no_update_news = true,
          },
          input = {
              kb_layout  = ${builtins.toJSON config.services.xserver.xkb.layout},
              kb_variant = ${builtins.toJSON config.services.xserver.xkb.variant},
              kb_options = ${builtins.toJSON config.services.xserver.xkb.options},
          },
      })
    '';
  in {
    imports = [inputs.shojiwm.nixosModules.default];

    options.shojiwm = {
      enable = lib.mkEnableOption "the ShojiWM Wayland compositor session with the Windows 7 configuration";

      checkout = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/home/sacha/Projects/shojiwm-win7";
        description = ''
          Path of a shojiwm-win7 checkout. If set, ~/.config/shojiwm links to
          this checkout instead of the packaged configuration.
        '';
      };

      greeter = {
        enable = lib.mkEnableOption ''
          the Windows 7 log-on screen of shojiwm-win7 as the display manager,
          through greetd, instead of ly. It logs userName on, into the session
          chosen in its corner (the last one used, first defaultSession)
        '';

        defaultSession = lib.mkOption {
          type = lib.types.str;
          default = config.display.defaultSession;
          defaultText = lib.literalExpression "config.display.defaultSession";
          example = "shojiwm-uwsm";
          description = "The session chosen the first time, by its .desktop file name.";
        };

        mainScreen = lib.mkOption {
          type = lib.types.str;
          default = "";
          example = "HDMI-A-1";
          description = ''
            Connector of the screen that shows the log-on box; the others stay
            black. Empty: the first screen.
          '';
        };
      };
    };

    # The module adds a ShojiWM session to the display manager. The default
    # session stays the one set in display.defaultSession.
    config = lib.mkIf config.shojiwm.enable {
      programs.shojiwm = {
        enable = true;
        # Creates package.json and the shoji_wm link in ~/.config/shojiwm.
        initConfig = {
          enable = true;
          users = [config.userName];
        };
      };

      # The "ShojiWM (UWSM)" session. uwsm stops graphical-session.target when
      # the compositor exits or crashes. The plain "ShojiWM" session leaves it
      # active after a crash, and uwsm then refuses to start Hyprland.
      # ShojiWM puts WAYLAND_DISPLAY into the systemd activation environment
      # itself, which is what uwsm waits for.
      #
      # X-NIXOS-SYSTEMD-AWARE stops the NixOS session wrapper from starting
      # nixos-fake-graphical-session.target before uwsm, which then refuses to
      # start. programs.uwsm.waylandCompositors writes no DesktopNames, so the
      # session file is written here.
      programs = {
        uwsm.enable = true;

        # The session's dconf profile: the same user database as Hyprland's, so
        # the settings stay shared, and before the system ones a database that
        # chooses the Aero icon theme, the desktop's icons, for Thunar and the
        # other GTK programs. A value written to the user database would still
        # come first, in both sessions.
        dconf.profiles.shojiwm = {
          enableUserDb = true;
          databases =
            [{settings."org/gnome/desktop/interface".icon-theme = "Aero";}]
            ++ config.programs.dconf.profiles.user.databases;
        };
      };
      services = {
        displayManager = {
          sessionPackages = [
            ((pkgs.writeTextDir "share/wayland-sessions/shojiwm-uwsm.desktop" ''
                [Desktop Entry]
                Name=ShojiWM (UWSM)
                Comment=ShojiWM managed by UWSM
                Exec=${lib.getExe config.programs.uwsm.package} start -e -D ShojiWM shojiwm.desktop
                DesktopNames=ShojiWM;X-NIXOS-SYSTEMD-AWARE
                Type=Application
              '')
              // {providedSessions = ["shojiwm-uwsm"];})
          ];
          # The log-on screen below replaces it.
          ly.enable = lib.mkIf config.shojiwm.greeter.enable false;
        };
        greetd = lib.mkIf config.shojiwm.greeter.enable {
          enable = true;
          settings.default_session.command = "${pkgs.hyprland}/bin/start-hyprland -- --config ${greeterHyprland}";
        };
      };

      environment = {
        # The session's environment, through uwsm's env file for ShojiWM
        # (XDG_CURRENT_DESKTOP lowercased): uwsm exports it to the systemd
        # user manager, which starts the compositor.
        # environment.sessionVariables does not reach it: the manager already
        # has __NIXOS_SET_ENVIRONMENT_DONE, so the login profile skips
        # /etc/set-environment.
        etc."xdg/uwsm/env-shojiwm".text = lib.concatStrings (lib.mapAttrsToList
          (name: value: "export ${name}=${lib.escapeShellArg value}\n")
          (lib.filterAttrs (_: value: value != "") {
            # ShojiWM sets no keymap; libxkbcommon then reads these.
            XKB_DEFAULT_LAYOUT = config.services.xserver.xkb.layout;
            XKB_DEFAULT_VARIANT = config.services.xserver.xkb.variant;
            XKB_DEFAULT_OPTIONS = config.services.xserver.xkb.options;
            # Print Screen in the Windows 7 configuration.
            SHOJIWM_WIN7_SCREENSHOT = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.screenshot;
            SHOJIWM_WIN7_OUTPUTS = outputRules;
            # The terminal the keys and the desktop open: the system's own.
            SHOJIWM_WIN7_TERMINAL = lib.attrByPath ["terminal" "command"] "" config;
            # Ctrl+Shift+Escape and the clock's menu: Mission Center.
            SHOJIWM_WIN7_TASK_MANAGER = "uwsm app -- missioncenter";
            # The CPU Meter gadget's button: btop in Ghostty.
            SHOJIWM_WIN7_SYSTEM_MONITOR = "uwsm app -- ghostty -e btop";
            # Super+V: Papier too.
            SHOJIWM_WIN7_CLIPBOARD = "papier toggle";
            # The dconf profile below: the Aero icon theme in this session.
            DCONF_PROFILE = "shojiwm";
            # Keys for programs that would register them through a
            # GlobalShortcuts portal, which ShojiWM does not have.
            # Hex binds its own keys through the GlobalShortcuts portal below.
            SHOJIWM_WIN7_KEYS = builtins.toJSON {
              # Ctrl+Shift+ù: Papier, the clipboard's history.
              "Ctrl+Shift+ugrave" = "papier toggle";
            };
          }));

        # The Windows 7 configuration needs these at run time. Hokum is its
        # command and launcher only (see hokumCommand).
        systemPackages =
          (with pkgs; [
            mission-center
            # The Aero icon theme inherits Oxygen.
            kdePackages.oxygen-icons
            inter
            kitty
            quickshell
            wl-clipboard
          ])
          ++ [hokumCommand inputs.shojiwm-win7.packages.${pkgs.stdenv.hostPlatform.system}.icon-theme];
      };

      # The GlobalShortcuts portal of shojiwm-win7: programs such as Hex bind
      # their keys through it. ShojiWM's own portal has only ScreenCast. The
      # name is the desktop's in lowercase: xdg-desktop-portal reads
      # shojiwm-portals.conf, where ShojiWM's module puts its own choices.
      xdg.portal = {
        extraPortals = [inputs.shojiwm-win7.packages.${pkgs.stdenv.hostPlatform.system}.portal];
        config.shojiwm."org.freedesktop.impl.portal.GlobalShortcuts" = ["shojiwm-win7"];
      };

      # Hokum shows the notifications in the ShojiWM session; dunst keeps
      # them in Hyprland. The service starts with the session, stops dunst and
      # takes the name.
      systemd.user.services.hokum-shojiwm = {
        description = "Hokum notifications in the ShojiWM session";
        wantedBy = ["wayland-session@shojiwm.desktop.target"];
        partOf = ["wayland-session@shojiwm.desktop.target"];
        after = ["wayland-session@shojiwm.desktop.target" "dunst.service"];
        # dunst, D-Bus activated, holds the name and does not give it up.
        conflicts = ["dunst.service"];
        serviceConfig = {
          ExecStart = "${lib.getExe hokum} service --replace";
          Restart = "on-failure";
        };
      };

      # The greeter keeps the last session chosen in its state folder
      # (~/.local/state), and Quickshell its cache.
      users.users.greeter = lib.mkIf config.shojiwm.greeter.enable {
        home = "/var/lib/greeter";
        createHome = true;
      };

      systemd.user.tmpfiles.users.${config.userName}.rules = map (name: "L+ ${configHome}/${name} - - - - ${configSource}/${name}") [
        "src"
        "assets"
        "shell"
      ];
    };
  };
}
