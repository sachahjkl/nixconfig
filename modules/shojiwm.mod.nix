{inputs, ...}: {
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

    # The Hyprland monitor rules, as ShojiWM output configuration: the same
    # modes, logical positions and scales in both sessions.
    hyprlandMonitors = lib.attrByPath ["hyprland" "display" "monitors"] [] config;
    toInts = separator: text: map lib.toInt (lib.splitString separator text);
    outputConfig = monitor:
      {
        resolution =
          if monitor.mode == "preferred"
          then "best"
          else let
            parts = lib.splitString "@" monitor.mode;
            size = toInts "x" (builtins.head parts);
          in
            {
              width = builtins.elemAt size 0;
              height = builtins.elemAt size 1;
            }
            // lib.optionalAttrs (builtins.length parts == 2) {
              refreshRate = lib.toInt (builtins.elemAt parts 1);
            };
        inherit (monitor) scale;
      }
      // lib.optionalAttrs (monitor.position != "auto") {
        position = let
          point = toInts "x" monitor.position;
        in {
          x = builtins.elemAt point 0;
          y = builtins.elemAt point 1;
        };
      };
    outputs =
      builtins.listToAttrs (map (monitor: lib.nameValuePair monitor.output (outputConfig monitor))
        (builtins.filter (monitor: monitor.output != "") hyprlandMonitors));
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
      programs.uwsm.waylandCompositors.shojiwm = {
        prettyName = "ShojiWM";
        comment = "ShojiWM managed by UWSM";
        binPath = "/run/current-system/sw/bin/shoji_wm";
        extraArgs = ["--tty"];
      };

      # Read by src/index.tsx of shojiwm-win7.
      environment.sessionVariables = lib.mkIf (outputs != {}) {
        SHOJIWM_WIN7_OUTPUTS = builtins.toJSON outputs;
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
