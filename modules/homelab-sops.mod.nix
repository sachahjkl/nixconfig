{self, ...}: {
  flake.nixosModules.homelabSops = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkOption mkDefault types;
    cfg = config.homelab.sops;
    passwordSecretName = "users/${config.userName}/password-hash";
  in {
    imports = [self.nixosModules.sops];

    options.homelab.sops = {
      enable = mkEnableOption "sops-nix integration for the homelab host";

      defaultSopsFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Encrypted SOPS file used by the homelab host.";
      };

      ageKeyFile = mkOption {
        type = types.str;
        default = "/var/lib/sops-nix/key.txt";
        description = "Age key file used by sops-nix on the homelab host.";
      };
    };

    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.defaultSopsFile != null;
          message = "homelab.sops.defaultSopsFile must point to an encrypted SOPS file when homelab.sops.enable = true.";
        }
      ];

      sops = {
        inherit (cfg) defaultSopsFile;
        defaultSopsFormat = "yaml";
        age.keyFile = cfg.ageKeyFile;

        secrets = {
          ${passwordSecretName} = {
            neededForUsers = true;
            path = "/run/secrets-for-users/${config.userName}-password-hash";
          };

          "restic/environment" = {
            owner = "root";
            group = "root";
            mode = "0400";
          };

          "restic/password" = {
            owner = "root";
            group = "root";
            mode = "0400";
          };
        };
      };

      secrets.userPasswordHashFile = mkDefault config.sops.secrets.${passwordSecretName}.path;
      homelab.backup.resticEnvironmentFile = mkDefault config.sops.secrets."restic/environment".path;
      homelab.backup.resticPasswordFile = mkDefault config.sops.secrets."restic/password".path;
    };
  };
}
