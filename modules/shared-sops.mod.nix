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

      sharedSecretsFile = lib.mkOption {
        type = lib.types.path;
        default = self + /secrets/shared.yaml;
        description = "Encrypted SOPS file containing shared cross-host secrets.";
      };

      passwordHashSecretName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "SOPS secret name containing the primary user's password hash.";
      };

      passwordHashFromSharedFile = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Read the password-hash secret from preferences.sops.sharedSecretsFile instead of the default SOPS file.";
      };
    };

    config = lib.mkIf cfg.enable {
      boot.initrd.availableKernelModules = {
        exfat = true;
        usb_storage = true;
        uas = true;
      };

      boot.supportedFilesystems.exfat = true;

      assertions = [
        {
          assertion = cfg.defaultSopsFile != null;
          message = "preferences.sops.defaultSopsFile must point to an encrypted SOPS file when preferences.sops.enable = true.";
        }
      ];

      sops = {
        inherit (cfg) defaultSopsFile;
        defaultSopsFormat = "yaml";
        age.keyFile = cfg.ageKeyFile;
      };

      sops.secrets = lib.mkIf (cfg.passwordHashSecretName != null) {
        ${cfg.passwordHashSecretName} =
          {
            neededForUsers = true;
            path = "/run/secrets-for-users/${config.userName}-password-hash";
          }
          // lib.optionalAttrs cfg.passwordHashFromSharedFile {
            sopsFile = cfg.sharedSecretsFile;
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
