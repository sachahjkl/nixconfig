{
  inputs,
  self,
  ...
}: {
  # The ShojiWM session as this system has it: shojiwm-desktop's module brings
  # the compositor, the configuration, the shell, the portal and the log-on
  # screen; what is chosen here is this user's (the programs the keys open,
  # Hokum for the notifications, the screens, what persists).
  flake.nixosModules.shojiwm = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (pkgs.stdenv.hostPlatform) system;
    hokum = inputs.hokum.packages.${system}.default;
    # Hokum's package also carries a D-Bus activation file for
    # org.freedesktop.Notifications, which would race dunst's in Hyprland:
    # only the command and the launcher are installed.
    hokumCommand = pkgs.runCommand "hokum-command" {} ''
      mkdir -p "$out/bin" "$out/share/applications"
      ln -s ${lib.getExe hokum} "$out/bin/hokum"
      ln -s ${hokum}/share/applications/hokum.desktop "$out/share/applications/hokum.desktop"
    '';

    # The screens, `name,mode,position,scale` separated by `;`, read by
    # src/index.tsx of shojiwm-desktop. The value holds no quotes: the session
    # environment files do not escape them.
    monitors = builtins.filter (monitor: monitor.output != "") config.display.monitors;
    outputRules = lib.concatMapStringsSep ";" (monitor: "${monitor.output},${monitor.mode},${monitor.position},${toString monitor.scale}") monitors;
    greeter = config.services.shojiwm-desktop-greeter;
  in {
    imports = [
      inputs.shojiwm-desktop.nixosModules.default
      self.nixosModules.classeur
      self.nixosModules.display
    ];

    config = lib.mkIf config.services.shojiwm-desktop.enable {
      services = {
        shojiwm-desktop = {
          users = [config.userName];
          environment = {
            # Print Screen in the Windows 7 configuration.
            SHOJIWM_DESKTOP_SCREENSHOT = lib.getExe self.packages.${system}.screenshot;
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
            # Keys for programs that do not use the GlobalShortcuts portal.
            SHOJIWM_DESKTOP_KEYS = builtins.toJSON {
              # Ctrl+Shift+ù: Papier, the clipboard's history.
              "Ctrl+Shift+ugrave" = "papier toggle";
            };
          };
        };

        # The log-on screen replaces ly, with the sessions' screens.
        displayManager.ly.enable = lib.mkIf greeter.enable false;
        shojiwm-desktop-greeter.monitors = map (monitor: {inherit (monitor) output mode position scale;}) monitors;
      };

      environment = {
        # Folders open in Classeur in this session only. GIO and xdg-mime read
        # <desktop>-mimeapps.list (XDG_CURRENT_DESKTOP lowercased) before
        # mimeapps.list; the other sessions keep Thunar.
        etc."xdg/shojiwm-mimeapps.list".text = ''
          [Default Applications]
          inode/directory=classeur.desktop
        '';

        systemPackages = [
          # The task manager; its package installs its desktop entry and icons.
          inputs.inspecteur.packages.${system}.default
          pkgs.kitty
          hokumCommand
        ];
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
        user.services.hokum-shojiwm = {
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

        # A drop-in on the unit dunst's package installs, as a plain file:
        # dunst does not start in a ShojiWM session, where Hokum has the
        # notifications.
        packages = [
          (pkgs.writeTextDir "lib/systemd/user/dunst.service.d/shojiwm.conf" ''
            [Unit]
            ConditionEnvironment=!XDG_CURRENT_DESKTOP=ShojiWM
          '')
        ];
      };

      # The log-on screen keeps the last session chosen in the greeter's
      # home, which the root's tmpfs would lose at each boot. greetd has no
      # automatic log-on of display.autoLoginUser.
      assertions = [
        {
          assertion = !(greeter.enable && config.services.displayManager.autoLogin.enable);
          message = "services.shojiwm-desktop-greeter and display.autoLoginUser do not go together: greetd's log-on screen has no automatic log-on.";
        }
      ];

      persist = {
        # settings.json, beside the links: what the Control Panel, the pins and
        # the notification area change. Hokum's config.kdl too: its theme, its
        # corner, its modules and Do not disturb.
        user.directories = [".config/shojiwm" ".config/hokum"];

        system.directories = lib.mkIf greeter.enable [
          {
            directory = "/var/lib/greeter";
            user = "greeter";
            group = "greeter";
            mode = "0700";
          }
        ];
      };
    };
  };
}
