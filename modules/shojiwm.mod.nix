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
      then inputs.shojiwm-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default
      else config.shojiwm.checkout;

    # The Hyprland monitor rules, `name,mode,position,scale` separated by
    # `;`, read by src/index.tsx of shojiwm-desktop. The value holds no quotes:
    # the session environment files do not escape them.
    monitors = builtins.filter (monitor: monitor.output != "") (lib.attrByPath ["hyprland" "display" "monitors"] [] config);
    outputRules = lib.concatMapStringsSep ";" (monitor: "${monitor.output},${monitor.mode},${monitor.position},${toString monitor.scale}") monitors;
  in {
    imports = [
      inputs.shojiwm.nixosModules.default
      inputs.shojiwm-desktop.nixosModules.greeter
      self.nixosModules.classeur
    ];

    options.shojiwm = {
      enable = lib.mkEnableOption "the ShojiWM Wayland compositor session with the Windows 7 configuration";

      checkout = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/home/sacha/Projects/shojiwm-desktop";
        description = ''
          Path of a shojiwm-desktop checkout. If set, ~/.config/shojiwm links to
          this checkout instead of the packaged configuration.
        '';
      };

      greeter = {
        enable = lib.mkEnableOption ''
          the Windows 7 log-on screen of shojiwm-desktop as the display manager,
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
        # shojiwm-desktop's log-on screen, with the sessions' screens.
        shojiwm-desktop-greeter = lib.mkIf config.shojiwm.greeter.enable {
          enable = true;
          user = config.userName;
          inherit (config.shojiwm.greeter) defaultSession mainScreen;
          monitors = map (monitor: {inherit (monitor) output mode position scale;}) monitors;
        };
      };

      environment = {
        # Folders open in Classeur in this session only. GIO and xdg-mime read
        # <desktop>-mimeapps.list (XDG_CURRENT_DESKTOP lowercased) before
        # mimeapps.list; the other sessions keep Thunar.
        etc."xdg/shojiwm-mimeapps.list".text = ''
          [Default Applications]
          inode/directory=classeur.desktop
        '';

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
            SHOJIWM_DESKTOP_SCREENSHOT = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.screenshot;
            SHOJIWM_DESKTOP_OUTPUTS = outputRules;
            # The terminal the keys and the desktop open: the system's own.
            SHOJIWM_DESKTOP_TERMINAL = lib.attrByPath ["terminal" "command"] "" config;
            # The file manager the keys and the desktop open: Classeur.
            SHOJIWM_DESKTOP_FILE_MANAGER = "uwsm app -- classeur";
            # Ctrl+Shift+Escape, the bar's and the clock's menus: inspecteur.
            SHOJIWM_DESKTOP_TASK_MANAGER = "uwsm app -- inspecteur";
            # The CPU Meter gadget's button: inspecteur, on its Performance section.
            SHOJIWM_DESKTOP_SYSTEM_MONITOR = "uwsm app -- inspecteur --section performance";
            # Super+V: Papier too.
            SHOJIWM_DESKTOP_CLIPBOARD = "papier toggle";
            # The dconf profile below: the Aero icon theme in this session.
            DCONF_PROFILE = "shojiwm";
            # Keys for programs that would register them through a
            # GlobalShortcuts portal, which ShojiWM does not have.
            # Hex binds its own keys through the GlobalShortcuts portal below.
            SHOJIWM_DESKTOP_KEYS = builtins.toJSON {
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
            wl-clipboard
          ])
          ++ (with inputs.shojiwm-desktop.packages.${pkgs.stdenv.hostPlatform.system}; [
            hokumCommand
            icon-theme
            # The shell: taskbar, Start menu, desktop, panels, lock screen.
            shell
          ]);
      };

      # The GlobalShortcuts portal of shojiwm-desktop: programs such as Hex bind
      # their keys through it. ShojiWM's own portal has only ScreenCast. The
      # name is the desktop's in lowercase: xdg-desktop-portal reads
      # shojiwm-portals.conf, where ShojiWM's module puts its own choices.
      xdg.portal = {
        extraPortals = [inputs.shojiwm-desktop.packages.${pkgs.stdenv.hostPlatform.system}.portal];
        config.shojiwm."org.freedesktop.impl.portal.GlobalShortcuts" = ["shojiwm-desktop"];
      };

      systemd = {
        # Hokum shows the notifications in the ShojiWM session; dunst keeps
        # them in Hyprland. The service starts with the session, stops a dunst
        # left from a Hyprland session (it holds the name and does not give it
        # up), and takes the name.
        #
        # No Conflicts= with dunst: it works both ways, so the first
        # notification that D-Bus-activated dunst stopped Hokum. dunst does not
        # start in a ShojiWM session instead.
        user.services = {
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
          # xdg-desktop-portal reads the desktop's portals.conf at its start, by
          # XDG_CURRENT_DESKTOP. Between two sessions (the user manager lives on:
          # another login keeps it), a call over D-Bus starts it without that
          # variable, and it then offers no GlobalShortcuts: Hex binds no key.
          # Once the session's variables are in, before graphical-session.target
          # (Hex starts after it), it is started again if it runs.
          portal-for-shojiwm = {
            description = "xdg-desktop-portal again with the ShojiWM session's variables";
            wantedBy = ["wayland-session@shojiwm.desktop.target"];
            after = ["wayland-wm@shojiwm.desktop.service"];
            before = ["graphical-session.target" "wayland-session@shojiwm.desktop.target"];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.systemd}/bin/systemctl --user try-restart xdg-desktop-portal.service";
            };
          };
          # A drop-in on the unit dunst's package installs; a whole unit here
          # would have no ExecStart.
        };

        # Drop-ins on units that packages install, as plain files: NixOS's
        # service options would write each with a PATH of its own (coreutils,
        # grep, sed, systemd), which the program then lives with. The portal had
        # it, and GIO, finding no browser on it, offered no app for a link.
        #
        # - dunst: not in a ShojiWM session, where Hokum has the notifications.
        # - xdg-desktop-portal: only inside a graphical session. It reads the
        #   desktop (XDG_CURRENT_DESKTOP) once, as it starts; woken by D-Bus
        #   between two sessions it had none, and kept no GlobalShortcuts for
        #   the next one (Hex had no keys). A call before fails; the next one,
        #   in the session, starts it right.
        packages = [
          (pkgs.writeTextDir "lib/systemd/user/dunst.service.d/shojiwm.conf" ''
            [Unit]
            ConditionEnvironment=!XDG_CURRENT_DESKTOP=ShojiWM
          '')
          (pkgs.writeTextDir "lib/systemd/user/xdg-desktop-portal.service.d/session.conf" ''
            [Unit]
            Requisite=graphical-session.target
            After=graphical-session.target
          '')
        ];

        user.tmpfiles.users.${config.userName}.rules = map (name: "L+ ${configHome}/${name} - - - - ${configSource}/${name}") [
          "src"
          "assets"
          "shell"
        ];
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
    };
  };
}
