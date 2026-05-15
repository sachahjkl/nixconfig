{ self, ... }:

{
  flake.nixosModules.hyprlandLock = { config, lib, pkgs, ... }:
    let
      desktopEnvironment = lib.attrByPath [ "desktop" "environment" ] null config;
      isHypr = lib.elem desktopEnvironment [ "hyprland" "both" "all" ];
      userName = config.sacha.userName;
      hyprlockPkg = self.lib.mkHyprlock {
        inherit pkgs;
        wallpaper = config.sacha.assets.wallpaper;
        faceIcon = config.sacha.assets.faceIcon;
      };
    in
    lib.mkIf isHypr {
      hjem.users.${userName}.xdg.config.files = {
        "hypr/hypridle.conf".text = ''
          general {
            lock_cmd = pidof hyprlock || ${lib.getExe hyprlockPkg}
            before_sleep_cmd = pidof hyprlock || ${lib.getExe hyprlockPkg}
            after_sleep_cmd = hyprctl dispatch dpms on
          }

          listener {
            timeout = 300
            on-timeout = pidof hyprlock || ${lib.getExe hyprlockPkg}
          }
        '';
      };
    };
}
