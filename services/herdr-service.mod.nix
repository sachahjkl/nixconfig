{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.herdrService = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.homelab.services.herdr;
    inherit (config) homeDirectory;
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
      system.services.herdr = {
        imports = [self.serviceModules.herdr];

        herdr.package = cfg.package;

        exec = {
          allow = [homeDirectory];
          environment = {
            HOME = homeDirectory;
            LOGNAME = config.userName;
            SHELL = toString config.users.users.${config.userName}.shell;
            USER = config.userName;
          };
          path = [config.system.path];
          workingDirectory = homeDirectory;
        };

        files.${homeDirectory} = ["read" "write"];

        systemd.service = {
          description = "Herdr terminal workspace server";
          after = ["network-online.target"];
          wants = ["network-online.target"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            User = config.userName;
            Group = "users";
            DynamicUser = lib.mkForce false;
            PrivateDevices = lib.mkForce false;
            PrivatePIDs = lib.mkForce false;
            PrivateUsers = lib.mkForce false;
            RestrictNamespaces = lib.mkForce false;
          };
        };
      };
    };
  };
}
