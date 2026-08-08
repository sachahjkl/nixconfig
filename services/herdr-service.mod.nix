{inputs, ...}: {
  flake.nixosModules.herdrService = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.homelab.services.herdr;
  in {
    options.homelab.services.herdr = {
      enable = lib.mkEnableOption "Herdr terminal workspace service";

      package = lib.mkOption {
        type = lib.types.package;
        default = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
        description = "Herdr package to run.";
      };
    };

    config = lib.mkIf cfg.enable {
      users.manageLingering = true;
      users.users.${config.userName}.linger = true;

      systemd.user.services.herdr = {
        description = "Herdr terminal workspace server";
        wantedBy = ["default.target"];
        path = [config.system.path];
        environment = {
          HOME = config.homeDirectory;
          LOGNAME = config.userName;
          SHELL = lib.getExe config.users.users.${config.userName}.shell;
          USER = config.userName;
        };
        serviceConfig = {
          ExecStart = "${lib.getExe cfg.package} server";
          Restart = "on-failure";
          RestartSec = 5;
          WorkingDirectory = config.homeDirectory;
        };
      };
    };
  };
}
