{ ... }:

{
  flake.nixosModules.gaming = { config, lib, pkgs, ... }:
    let
      cfg = config.gaming;
      boolDefault = default: lib.mkOption {
        type = lib.types.bool;
        inherit default;
      };
    in
    {
      options.gaming = {
        steam.enable = boolDefault true;
        steam.gamescopeSession.enable = boolDefault false;
        steam.remotePlay.openFirewall = boolDefault true;
        steam.dedicatedServer.openFirewall = boolDefault true;

        vinegar.enable = boolDefault true;

        mangohud.enable = boolDefault true;
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.steam.enable {
          programs.steam = {
            enable = true;
            remotePlay.openFirewall = cfg.steam.remotePlay.openFirewall;
            dedicatedServer.openFirewall = cfg.steam.dedicatedServer.openFirewall;
            gamescopeSession.enable = cfg.steam.gamescopeSession.enable;
          };
        })

        (lib.mkIf cfg.vinegar.enable {
          environment.systemPackages = [ pkgs.vinegar ];
        })

        (lib.mkIf cfg.mangohud.enable {
          environment.systemPackages = [ pkgs.mangohud ];
        })
      ];
    };
}
