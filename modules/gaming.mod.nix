_: {
  flake.nixosModules.gaming = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.gaming;
    boolDefault = default:
      lib.mkOption {
        type = lib.types.bool;
        inherit default;
      };
  in {
    options.gaming = {
      steam = {
        enable = boolDefault true;
        gamescopeSession.enable = boolDefault false;
        remotePlay.openFirewall = boolDefault true;
        dedicatedServer.openFirewall = boolDefault true;
      };

      vinegar.enable = boolDefault true;

      mangohud.enable = boolDefault true;

      streaming = {
        moonlight.enable = boolDefault true;

        sunshine = {
          enable = boolDefault false;
          autoStart = boolDefault true;
          openFirewall = boolDefault true;
          capSysAdmin = boolDefault true;
          cudaSupport = boolDefault false;
        };
      };
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
        environment.systemPackages = [pkgs.vinegar];
      })

      (lib.mkIf cfg.mangohud.enable {
        environment.systemPackages = [pkgs.mangohud];
      })

      (lib.mkIf cfg.streaming.moonlight.enable {
        environment.systemPackages = [pkgs.moonlight-qt];
      })

      (lib.mkIf cfg.streaming.sunshine.enable {
        services.sunshine = {
          enable = true;
          autoStart = cfg.streaming.sunshine.autoStart;
          openFirewall = cfg.streaming.sunshine.openFirewall;
          capSysAdmin = cfg.streaming.sunshine.capSysAdmin;
          package =
            if cfg.streaming.sunshine.cudaSupport
            then
              pkgs.sunshine.override {
                cudaSupport = true;
                inherit (pkgs) cudaPackages;
              }
            else pkgs.sunshine;
        };
      })
    ];
  };
}
