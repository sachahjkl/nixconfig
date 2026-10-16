_: {
  flake.nixosModules.sqliteSnapshots = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) concatStringsSep escapeShellArg mapAttrsToList mkEnableOption mkOption types;
    cfg = config.services.sqliteSnapshots;
  in {
    options.services.sqliteSnapshots = {
      enable = mkEnableOption "consistent snapshots of live SQLite databases before backups";

      directory = mkOption {
        type = types.str;
        description = "Directory receiving one consistent copy per database, to include in backups.";
      };

      databases = mkOption {
        type = types.attrsOf types.str;
        default = {};
        example = {petitpecule = "/data/Services/nomad/volumes/*/petitpecule.db";};
        description = ''
          Snapshot name mapped to the database path. Shell globs are allowed because Nomad host
          volumes live in generated directories; the pattern must match at most one file.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.databases != {};
          message = "services.sqliteSnapshots.databases must not be empty when snapshots are enabled.";
        }
      ];

      systemd.tmpfiles.rules = ["d ${cfg.directory} 0700 root root -"];

      # A file copy of a database in WAL mode can pair a database and a journal from different moments:
      # SQLite's online backup gives a consistent copy without stopping the application.
      systemd.services.sqlite-snapshots = {
        description = "Consistent snapshots of live SQLite databases";
        path = [pkgs.coreutils pkgs.sqlite];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          UMask = "0077";
        };
        script = ''
          set -euo pipefail
          shopt -s nullglob

          snapshot() {
            local name="$1" pattern="$2" matches
            # shellcheck disable=SC2206
            matches=($pattern)
            if [ "''${#matches[@]}" -eq 0 ]; then
              echo "$name: no database matches $pattern, skipped"
              return
            fi
            if [ "''${#matches[@]}" -gt 1 ]; then
              echo "$name: $pattern matches several databases: ''${matches[*]}" >&2
              return 1
            fi

            local target=${escapeShellArg cfg.directory}/"$name.db"
            local partial="$target.partial"
            rm -f "$partial"
            sqlite3 -readonly "''${matches[0]}" ".backup '$partial'"
            if [ "$(sqlite3 "$partial" 'PRAGMA integrity_check;')" != "ok" ]; then
              echo "$name: integrity check failed on the snapshot" >&2
              rm -f "$partial"
              return 1
            fi
            mv -f "$partial" "$target"
            echo "$name: snapshot of ''${matches[0]} saved to $target"
          }

          ${concatStringsSep "\n" (mapAttrsToList (name: pattern: "snapshot ${escapeShellArg name} ${escapeShellArg pattern}") cfg.databases)}
        '';
      };
    };
  };
}
