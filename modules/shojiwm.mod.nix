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

      environment.sessionVariables =
        # ShojiWM sets no keymap; libxkbcommon then reads these.
        lib.filterAttrs (_: value: value != "") {
          XKB_DEFAULT_LAYOUT = config.services.xserver.xkb.layout;
          XKB_DEFAULT_VARIANT = config.services.xserver.xkb.variant;
          XKB_DEFAULT_OPTIONS = config.services.xserver.xkb.options;
        }
        // {
          # Print Screen in the Windows 7 configuration.
          SHOJIWM_WIN7_SCREENSHOT = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.screenshot;
        }
        // lib.optionalAttrs (outputRules != "") {
          SHOJIWM_WIN7_OUTPUTS = outputRules;
        };

      # The Windows 7 configuration needs these at run time.
      # The package writes the store path of Vicinae into the configuration.
      # A checkout calls `vicinae` through PATH.
      environment.systemPackages =
        (with pkgs; [
          inter
          kitty
          quickshell
        ])
        ++ lib.optional (config.shojiwm.checkout != null) pkgs.vicinae;

      systemd.user.tmpfiles.users.${config.userName}.rules = map (name: "L+ ${configHome}/${name} - - - - ${configSource}/${name}") [
        "src"
        "assets"
        "shell"
      ];
    };
  };
}
