{inputs, ...}: {
  flake.nixosModules.hermesDashboard = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkOption types;
    cfg = config.homelab.services.hermesDashboard;
    hermesPackage = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
  in {
    options.homelab.services.hermesDashboard = {
      enable = mkEnableOption "Hermes dashboard service";

      package = mkOption {
        type = types.package;
        default = hermesPackage;
      };

      stateDir = mkOption {
        type = types.str;
        default = "/var/lib/hermes";
      };

      workingDirectory = mkOption {
        type = types.str;
        default = "${cfg.stateDir}/.hermes";
      };

      port = mkOption {
        type = types.port;
        default = 9119;
      };
    };

    config = mkIf cfg.enable {
      systemd.tmpfiles.rules = [
        "d ${cfg.stateDir} 0750 root root -"
        "d ${cfg.workingDirectory} 0750 root root -"
      ];

      systemd.services.hermes-dashboard = {
        description = "Hermes Agent Web Dashboard";
        documentation = ["https://hermes-agent.nousresearch.com/docs/user-guide/features/web-dashboard"];
        after = ["network-online.target"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
        startLimitIntervalSec = 0;
        serviceConfig = {
          Type = "simple";
          User = "root";
          WorkingDirectory = cfg.workingDirectory;
          ExecStart = "${cfg.package}/bin/hermes dashboard --port ${toString cfg.port} --host 0.0.0.0 --insecure --tui --no-open";
          Environment = ["HERMES_HOME=${cfg.workingDirectory}"];
          Restart = "always";
          RestartSec = 5;
          RestartMaxDelaySec = 300;
          RestartSteps = 5;
          RestartForceExitStatus = 75;
          KillMode = "mixed";
          KillSignal = "SIGTERM";
          TimeoutStopSec = 30;
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };
    };
  };
}
