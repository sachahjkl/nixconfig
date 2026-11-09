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
    outputRules = lib.concatMapStringsSep ";" (monitor: "${monitor.output},${monitor.mode},${monitor.position},${toString monitor.scale}") (
      builtins.filter (monitor: monitor.output != "") (lib.attrByPath ["hyprland" "display" "monitors"] [] config)
    );
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
      programs.uwsm.enable = true;
      services.displayManager.sessionPackages = [
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
            # Ctrl+Shift+Escape: btop in Ghostty, as the task manager.
            SHOJIWM_WIN7_TASK_MANAGER = "uwsm app -- ghostty -e btop";
            # Keys for programs that would register them through a
            # GlobalShortcuts portal, which ShojiWM does not have.
            SHOJIWM_WIN7_KEYS = builtins.toJSON ({
                # Ctrl+Shift+ù: Papier, the clipboard's history.
                "Ctrl+Shift+ugrave" = "papier toggle";
              }
              // lib.optionalAttrs (lib.attrByPath ["ai" "hex" "enable"] false config) {
                "Ctrl+Shift+Space" = "hex dictation toggle";
              });
          }));

        # The Windows 7 configuration needs these at run time. The package
        # writes the store path of Vicinae into the configuration; a checkout
        # calls `vicinae` through PATH. Hokum is its command and launcher
        # only (see hokumCommand).
        systemPackages =
          (with pkgs; [
            # Super+V: the clipboard history.
            cliphist
            inter
            kitty
            quickshell
            wl-clipboard
          ])
          ++ [hokumCommand]
          ++ lib.optional (config.shojiwm.checkout != null) pkgs.vicinae;
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

      systemd.user.tmpfiles.users.${config.userName}.rules = map (name: "L+ ${configHome}/${name} - - - - ${configSource}/${name}") [
        "src"
        "assets"
        "shell"
      ];
    };
  };
}
