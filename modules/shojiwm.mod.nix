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
  in {
    imports = [inputs.shojiwm.nixosModules.default inputs.shojiwm-win7.nixosModules.greeter];

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
        # shojiwm-win7's log-on screen, with the sessions' screens.
        shojiwm-win7-greeter = lib.mkIf config.shojiwm.greeter.enable {
          enable = true;
          user = config.userName;
          inherit (config.shojiwm.greeter) defaultSession mainScreen;
          monitors = map (monitor: {inherit (monitor) output mode position scale;}) monitors;
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
            # Ctrl+Shift+Escape, the bar's and the clock's menus: inspecteur.
            SHOJIWM_WIN7_TASK_MANAGER = "uwsm app -- inspecteur";
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
          [
            # The task manager; its package installs its desktop entry and
            # its icons.
            inputs.inspecteur.packages.${pkgs.stdenv.hostPlatform.system}.default
          ]
          ++ (with pkgs; [
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
      # them in Hyprland. The service starts with the session, stops a dunst
      # left from a Hyprland session (it holds the name and does not give it
      # up), and takes the name.
      #
      # No Conflicts= with dunst: it works both ways, so the first
      # notification that D-Bus-activated dunst stopped Hokum. dunst does not
      # start in a ShojiWM session instead.
      systemd.user.services = {
        hokum-shojiwm = {
          description = "Hokum notifications in the ShojiWM session";
          wantedBy = ["wayland-session@shojiwm.desktop.target"];
          partOf = ["wayland-session@shojiwm.desktop.target"];
          after = ["wayland-session@shojiwm.desktop.target" "dunst.service"];
          serviceConfig = {
            # "-": without dunst installed, the stop fails and that is fine.
            ExecStartPre = "-${pkgs.systemd}/bin/systemctl --user stop dunst.service";
            ExecStart = "${lib.getExe hokum} service --replace";
            Restart = "on-failure";
          };
        };
        # A drop-in on the unit dunst's package installs; a whole unit here
        # would have no ExecStart.
        dunst = {
          overrideStrategy = "asDropin";
          unitConfig.ConditionEnvironment = "!XDG_CURRENT_DESKTOP=ShojiWM";
        };
        # The portal reads the desktop (XDG_CURRENT_DESKTOP) once, as it
        # starts. At a log-out uwsm stops it and clears the session's
        # environment; a program still running then woke it by D-Bus
        # between the two sessions, without the desktop, and that portal
        # stayed for the next session: no GlobalShortcuts, so Hex had no
        # keys. It starts only inside a graphical session now; a call
        # before fails, and the next one, in the session, starts it right.
        xdg-desktop-portal = {
          overrideStrategy = "asDropin";
          requisite = ["graphical-session.target"];
          after = ["graphical-session.target"];
        };
      };

      # The log-on screen keeps the last session chosen in the greeter's
      # home, which the root's tmpfs would lose at each boot. greetd has no
      # automatic log-on of display.autoLoginUser.
      assertions = [
        {
          assertion = !(config.shojiwm.greeter.enable && config.services.displayManager.autoLogin.enable);
          message = "shojiwm.greeter and display.autoLoginUser do not go together: greetd's log-on screen has no automatic log-on.";
        }
      ];
      # settings.json, beside the links below: what the Control Panel, the
      # pins and the notification area change. The root's tmpfs would lose it
      # at each boot.
      #
      # Hokum's config.kdl too: its theme (assets/hokum/aero.kdl), its corner
      # and its modules, and Do not disturb, which it writes there.
      persist.user.directories = [".config/shojiwm" ".config/hokum"];

      persist.system.directories = lib.mkIf config.shojiwm.greeter.enable [
        {
          directory = "/var/lib/greeter";
          user = "greeter";
          group = "greeter";
          mode = "0700";
        }
      ];

      systemd.user.tmpfiles.users.${config.userName}.rules = map (name: "L+ ${configHome}/${name} - - - - ${configSource}/${name}") [
        "src"
        "assets"
        "shell"
      ];
    };
  };
}
