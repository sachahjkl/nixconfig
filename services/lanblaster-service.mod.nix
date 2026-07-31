{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.lanblasterService = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
    cfg = config.homelab.services.lanblaster;
    package = inputs.lanblaster.packages.${pkgs.stdenv.hostPlatform.system}.lanblaster;
  in {
    options.homelab.services.lanblaster = {
      enable = mkEnableOption "lanblaster.sacha.house game server";

      package = mkOption {
        type = types.package;
        default = package;
        description = "lanblaster.sacha.house package to run.";
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Interface the game server listens on.";
      };

      port = mkOption {
        type = types.port;
        default = 8013;
        description = "Port the game server listens on.";
      };
    };

    config = mkIf cfg.enable {
      system.services.lanblaster = {
        imports = [self.serviceModules.lanblaster];
        lanblaster = {
          inherit (cfg) package host port;
        };
      };

      homelab.proxy.hosts."lanblaster.sacha.house" = {
        upstreamHost = mkDefault "127.0.0.1";
        upstreamPort = mkDefault cfg.port;
        websockets = mkDefault true;
      };
    };
  };
}
