{ self, ... }:

{
  flake.nixosModules.hyprlandLock = { config, lib, pkgs, ... }:
    let
      userName = config.userName;
      hyprlockPkg = self.lib.mkHyprlock {
        inherit pkgs;
        wallpaper = config.assets.wallpaper;
        faceIcon = config.assets.faceIcon;
      };
    in
    {
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
