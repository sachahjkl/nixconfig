{self, ...}: {
  flake.nixosModules.sharedSops = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    cfg = config.sharedSops;
    isWsl = lib.attrByPath ["wsl" "enable"] false config;
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
    hasPasswordHashFile = lib.hasAttrByPath ["passwordHashFile"] options;
    hasPersistDirs = lib.hasAttrByPath ["persist" "user" "directories"] options;
    hasUserName = lib.hasAttrByPath ["userName"] options;
  in {
    imports = [self.nixosModules.sops];

    options.sharedSops = {
      enable = lib.mkEnableOption "shared sops-nix integration";

      defaultSopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = builtins.path {
          path = self + /secrets/shared.yaml;
          name = "shared-secrets.yaml";
        };
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
        description = "Optional encrypted SOPS file used specifically for the password-hash secret. When null, the secret is read from sharedSops.defaultSopsFile.";
      };
    };

    config = lib.mkIf cfg.enable (lib.mkMerge [
      (lib.mkIf (!isWsl) {
        boot = {
          initrd.availableKernelModules = {
            exfat = true;
            usb_storage = true;
            uas = true;
          };

          supportedFilesystems.exfat = true;
        };

        environment.systemPackages = [
          pkgs.cryptsetup
          pkgs.exfatprogs
        ];
      })

      {
        assertions = [
          {
            assertion = cfg.defaultSopsFile != null;
            message = "sharedSops.defaultSopsFile must point to an encrypted SOPS file when sharedSops.enable = true.";
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

          secrets = lib.mkIf (cfg.passwordHashSecretName != null && hasUserName) {
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
      }

      (lib.optionalAttrs hasPasswordHashFile {
        passwordHashFile = lib.mkIf (cfg.passwordHashSecretName != null) (lib.mkDefault config.sops.secrets.${cfg.passwordHashSecretName}.path);
      })

      (lib.optionalAttrs (hasHjemUsers && hasUserName) {
        hjem.users.${config.userName}.xdg.config.files."sops/age".type = "directory";
      })

      (lib.optionalAttrs hasPersistDirs {
        persist.user.directories = [".config/sops"];
      })
    ]);
  };
}
