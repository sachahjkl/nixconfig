{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.clockinService = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
    cfg = config.homelab.services.clockin;
    package = inputs.clockin.packages.${pkgs.stdenv.hostPlatform.system}.default;
  in {
    options.homelab.services.clockin = {
      enable = mkEnableOption "clockin.sacha.house web service";

      package = mkOption {
        type = types.package;
        default = package;
        description = "Clock-in package to run.";
      };

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

      allowedHosts = mkOption {
        type = types.listOf types.str;
        default = ["clockin.sacha.house" "127.0.0.1" "localhost"];
        description = "Allowed Host headers for Angular SSR host validation.";
      };
    };

    config = mkIf cfg.enable {
      users.users.clockin = {
        isSystemUser = true;
        group = "clockin";
        home = cfg.databaseDir;
      };
      users.groups.clockin = {};

      system.services.clockin = {
        imports = [self.serviceModules.clockin];
        clockin = {
          inherit (cfg) package host port databaseDir allowedHosts;
        };
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.databaseDir} 0755 clockin clockin -"
      ];

      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [cfg.port];

      homelab.proxy.hosts."clockin.sacha.house" = {
        upstreamHost = mkDefault "127.0.0.1";
        upstreamPort = mkDefault cfg.port;
      };
    };
  };
}
