{inputs, ...}: {
  flake.nixosModules.albumatorService = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
    cfg = config.homelab.services.albumator;
  in {
    imports = [inputs.albumator.nixosModules.default];

    options.homelab.services.albumator = {
      enable = mkEnableOption "albumator.sacha.house web service";

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Host address to bind the albumator service to.";
      };

      port = mkOption {
        type = types.port;
        default = 3000;
        description = "Port for the albumator service.";
      };

      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/albumator";
        description = "Directory where Albumator stores its database and cached image variants.";
      };

      databaseUrl = mkOption {
        type = types.str;
        default = "file:${cfg.dataDir}/local.db";
        description = "SQLite connection URL for Albumator.";
      };

      publicGitRepoId = mkOption {
        type = types.str;
        default = "sachahjkl/albumator";
        description = "Repository identifier used in footer/build metadata.";
      };

      environmentFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Optional environment file for Albumator runtime secrets or overrides.";
      };
    };

    config = mkIf cfg.enable {
      services.albumator = {
        enable = true;
        inherit (cfg) host port dataDir databaseUrl publicGitRepoId environmentFile;
      };

      homelab.proxy.hosts."albumator.sacha.house" = {
        upstreamHost = mkDefault "127.0.0.1";
        upstreamPort = mkDefault cfg.port;
      };
    };
  };
}
