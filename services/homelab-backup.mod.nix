_: {
  flake.nixosModules.homelabBackup = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) escapeShellArg mkOption types;
    cfg = config.homelab;
  in {
    options.homelab.backup = {
      resticEnvironmentFile = mkOption {
        type = types.str;
        default = "/root/.restic-env";
        description = "Shell fragment that exports the Restic backend credentials.";
      };

      resticPasswordFile = mkOption {
        type = types.str;
        default = "/root/.restic-pw";
        description = "Path to the Restic repository password file.";
      };
    };

    config = {
      systemd.services.homelab-restic-backup = {
        description = "Homelab restic backup";
        path = [pkgs.bash pkgs.coreutils pkgs.gnugrep pkgs.restic];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          EnvironmentFile = cfg.backup.resticEnvironmentFile;
        };
        script = ''
          set -euo pipefail
          export RESTIC_PASSWORD_FILE=${escapeShellArg cfg.backup.resticPasswordFile}

          restic backup \
            /etc \
            /root \
            /data/Secrets \
            /data/Services \
            /data/Docker/appdata \
            /data/Home \
            --exclude=".cache" \
            --exclude=".npm" \
            --exclude=".bun" \
            --exclude=".cargo" \
            --exclude=".rustup" \
            --exclude="node_modules" \
            --exclude=".git" \
            --exclude="tmp" \
            --exclude=".local/share/Trash" \
            --exclude="storage" \
            --exclude="appdata.bak"

          restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune || true
        '';
      };

      systemd.timers.homelab-restic-backup = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "04:00";
          Persistent = true;
          RandomizedDelaySec = "15m";
        };
      };
    };
  };
}
