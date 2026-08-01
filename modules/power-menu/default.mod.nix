{self, ...}: {
  flake.nixosModules.powerMenu = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.powerMenu;
    choices = lib.concatStringsSep "/" cfg.choices;
    powerMenu = self.packages.${pkgs.stdenv.hostPlatform.system}.rofi-power-menu;
    powerMenuMode = pkgs.writeShellApplication {
      name = "rofi-power-menu-mode";
      runtimeInputs = [powerMenu];
      text = ''
        exec rofi-power-menu --choices=${lib.escapeShellArg choices} "$@"
      '';
    };
    launcher = pkgs.writeShellApplication {
      name = "rofi-power-menu-launcher";
      runtimeInputs = [cfg.rofiPackage powerMenuMode];
      text = ''
        exec rofi -show power-menu -modes "power-menu:rofi-power-menu-mode"
      '';
    };
  in {
    options.powerMenu = {
      choices = lib.mkOption {
        type = lib.types.nonEmptyListOf (lib.types.enum ["lockscreen" "logout" "suspend" "hibernate" "shutdown" "reboot"]);
        default = ["lockscreen" "logout" "suspend" "hibernate" "shutdown" "reboot"];
        description = "Ordered actions displayed in the power menu.";
      };

      rofiPackage = lib.mkOption {
        type = lib.types.package;
        default = pkgs.rofi;
        description = "Rofi package used to display the power menu.";
      };

      package = lib.mkOption {
        type = lib.types.package;
        readOnly = true;
        internal = true;
        description = "Shared power menu launcher.";
      };
    };

    config = {
      powerMenu.package = launcher;
      environment.systemPackages = [powerMenu];
    };
  };

  perSystem = {pkgs, ...}: {
    packages.rofi-power-menu = pkgs.writeTextFile {
      name = "rofi-power-menu";
      destination = "/bin/rofi-power-menu";
      executable = true;
      text =
        builtins.replaceStrings
        ["@nushell@" "@loginctl@" "@systemctl@" "@uwsm@"]
        [
          (pkgs.lib.getExe pkgs.nushell)
          (pkgs.lib.getExe' pkgs.systemd "loginctl")
          (pkgs.lib.getExe' pkgs.systemd "systemctl")
          (pkgs.lib.getExe pkgs.uwsm)
        ]
        (builtins.readFile ./power-menu.nu);
    };
  };
}
