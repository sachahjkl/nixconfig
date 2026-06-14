{self, ...}: {
  flake.nixosModules.sharedSops = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    cfg = config.preferences.sops;
    hasPasswordHashFile = lib.hasAttrByPath ["passwordHashFile"] options;
  in {
    imports = [self.nixosModules.sops];

    options.preferences.sops = {
      enable = lib.mkEnableOption "shared sops-nix integration";

      defaultSopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = self + /secrets/shared.yaml;
        description = "Encrypted SOPS file used by this host.";
      };

      ageKeyFile = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/sops-nix/key.txt";
        description = "Age key file used by sops-nix on this host.";
      };

      passwordHashSecretName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "SOPS secret name containing the primary user's password hash.";
      };

      passwordHashSopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Optional encrypted SOPS file used specifically for the password-hash secret. When null, the secret is read from preferences.sops.defaultSopsFile.";
      };
    };

    config = lib.mkIf cfg.enable {
      boot = {
        initrd.availableKernelModules = {
          exfat = true;
          usb_storage = true;
          uas = true;
        };

        supportedFilesystems.exfat = true;
      };

      assertions = [
        {
          assertion = cfg.defaultSopsFile != null;
          message = "preferences.sops.defaultSopsFile must point to an encrypted SOPS file when preferences.sops.enable = true.";
        }
      ];

      sops = {
        inherit (cfg) defaultSopsFile;
        defaultSopsFormat = "yaml";

        age = {
          keyFile = cfg.ageKeyFile;
          sshKeyPaths = [];
        };

        gnupg.sshKeyPaths = [];

        secrets = lib.mkIf (cfg.passwordHashSecretName != null) {
          ${cfg.passwordHashSecretName} =
            {
              neededForUsers = true;
              path = "/run/secrets-for-users/${config.userName}-password-hash";
            }
            // lib.optionalAttrs (cfg.passwordHashSopsFile != null) {
              sopsFile = cfg.passwordHashSopsFile;
            };
        };
      };

      passwordHashFile = lib.mkIf (hasPasswordHashFile && cfg.passwordHashSecretName != null) (lib.mkDefault config.sops.secrets.${cfg.passwordHashSecretName}.path);

      environment.systemPackages = [
        pkgs.cryptsetup
        pkgs.exfatprogs
      ];
    };
  };
}
