{inputs, ...}: {
  flake.nixosModules.clockinService = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
    cfg = config.homelab.services.clockin;
  in {
    imports = [inputs.clockin.nixosModules.default];

    options.homelab.services.clockin = {
      enable = mkEnableOption "clockin.sacha.house web service";

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Host address to bind the clockin service to.";
      };

      port = mkOption {
        type = types.port;
        default = 3000;
        description = "Port for the clockin service.";
      };

      databaseDir = mkOption {
        type = types.path;
        default = "/var/lib/clockin";
        description = "Directory where the SQLite database is stored.";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = "Open the configured port in the firewall.";
      };
    };

    config = mkIf cfg.enable {
      services.clockin = {
        enable = true;
        inherit (cfg) host port databaseDir openFirewall;
      };

      homelab.proxy.hosts."clockin.sacha.house" = {
        upstreamHost = mkDefault "127.0.0.1";
        upstreamPort = mkDefault cfg.port;
      };
    };
  };
}
