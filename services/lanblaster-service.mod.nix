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

      user = mkOption {
        type = types.str;
        default = "lanblaster";
        description = "User that runs the game server.";
      };

      group = mkOption {
        type = types.str;
        default = "lanblaster";
        description = "Group that runs the game server.";
      };
    };

    config = mkIf cfg.enable {
      users.users.lanblaster = {
        isSystemUser = true;
        inherit (cfg) group;
        home = "/var/lib/lanblaster";
        createHome = true;
      };
      users.groups.lanblaster = {};

      systemd.services.lanblaster = {
        description = "Lanblaster game server";
        after = ["network-online.target"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
        startLimitIntervalSec = 0;
        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = "${cfg.package}/share/lanblaster";
          ExecStart = "${cfg.package}/bin/lanblaster-server";
          Environment = [
            "HOST=${cfg.host}"
            "PORT=${toString cfg.port}"
          ];
          Restart = "on-failure";
          RestartSec = 10;
          StandardOutput = "journal";
          StandardError = "journal";
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
