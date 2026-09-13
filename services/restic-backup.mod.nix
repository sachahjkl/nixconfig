_: {
  flake.nixosModules.resticBackup = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) escapeShellArg escapeShellArgs mkEnableOption mkOption types;
    cfg = config.services.resticBackup;
    backupArguments = cfg.paths ++ map (pattern: "--exclude=${pattern}") cfg.excludes;
  in {
    options.services.resticBackup = {
      enable = mkEnableOption "scheduled Restic backups";

      environmentFile = mkOption {
        type = types.str;
        description = "Shell fragment that exports the Restic backend credentials.";
      };

      passwordFile = mkOption {
        type = types.str;
        description = "Path to the Restic repository password file.";
      };

      paths = mkOption {
        type = types.listOf types.str;
        description = "Paths included in each backup.";
      };

      excludes = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "File names and patterns excluded from each backup.";
      };

      keepDaily = mkOption {
        type = types.ints.unsigned;
        default = 7;
        description = "Number of daily snapshots to retain.";
      };

      keepWeekly = mkOption {
        type = types.ints.unsigned;
        default = 4;
        description = "Number of weekly snapshots to retain.";
      };

      keepMonthly = mkOption {
        type = types.ints.unsigned;
        default = 6;
        description = "Number of monthly snapshots to retain.";
      };

      schedule = mkOption {
        type = types.str;
        default = "04:00";
        description = "Systemd calendar expression for backup runs.";
      };
    };

    config = lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.paths != [];
          message = "services.resticBackup.paths must not be empty when backups are enabled.";
        }
      ];

      systemd.services.restic-backup = {
        description = "Restic backup";
        path = [pkgs.bash pkgs.coreutils pkgs.gnugrep pkgs.restic];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          EnvironmentFile = cfg.environmentFile;
        };
        script = ''
          set -euo pipefail
          export RESTIC_PASSWORD_FILE=${escapeShellArg cfg.passwordFile}

          restic unlock
          restic backup ${escapeShellArgs backupArguments}

          restic forget \
            --keep-daily ${toString cfg.keepDaily} \
            --keep-weekly ${toString cfg.keepWeekly} \
            --keep-monthly ${toString cfg.keepMonthly} \
            --prune
        '';
      };

      systemd.timers.restic-backup = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = cfg.schedule;
          Persistent = true;
          RandomizedDelaySec = "15m";
        };
      };
    };
  };
}
