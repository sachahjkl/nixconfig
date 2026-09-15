_: {
  flake.nixosModules.filebrowser = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.filebrowser;
    inherit (lib) mkIf mkOption types;
  in {
    options.services.filebrowser = {
      adminPasswordFile = mkOption {
        type = types.path;
        description = "File containing the File Browser administrator password.";
      };
    };

    config = mkIf cfg.enable {
      systemd.services.filebrowser.preStart = let
        database = cfg.settings.database;
        filebrowser = lib.getExe pkgs.filebrowser;
      in ''
        password="$(cat ${lib.escapeShellArg cfg.adminPasswordFile})"

        if [[ ! -e ${lib.escapeShellArg database} ]]; then
          ${filebrowser} config init --database ${lib.escapeShellArg database}
          ${filebrowser} users add admin "$password" --perm.admin --database ${lib.escapeShellArg database}
        else
          ${filebrowser} users update admin --password "$password" --database ${lib.escapeShellArg database}
        fi
      '';
    };
  };
}
