{ inputs, ... }:

{
  flake.nixosModules.secrets = { config, lib, ... }:
    let
      inherit (lib) mkDefault mkIf mkMerge types;
      hasMediaKeyIdentity = builtins.any (path: lib.hasPrefix "/media/key/" path) config.age.identityPaths;
    in
    {
      imports = [ inputs.agenix.nixosModules.default ];

      options.secrets = {
        userPasswordHash = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Primary local user password hash.";
        };

        userPasswordHashFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to a password-hash file, typically provisioned by sops-nix or agenix.";
        };

        userPasswordHashAgeFile = lib.mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Encrypted agenix file containing the primary local user password hash.";
        };
      };

      config = mkMerge [
        {
          age.identityPaths = mkDefault [ ];
        }

        (mkIf (config.secrets.userPasswordHashAgeFile != null) {
          age.secrets.userPasswordHash = {
            file = config.secrets.userPasswordHashAgeFile;
            path = "/run/secrets-for-users/${config.userName}-password-hash";
          };

          secrets.userPasswordHashFile = mkDefault config.age.secrets.userPasswordHash.path;
        })

        (mkIf hasMediaKeyIdentity {
          boot.initrd.availableKernelModules = [
            "exfat"
            "usb_storage"
            "uas"
          ];

          fileSystems."/media/key" = {
            device = "/dev/disk/by-label/${config.networking.hostName}.s";
            fsType = "exfat";
            options = [
              "ro"
              "umask=0077"
            ];
            neededForBoot = true;
          };
        })
      ];
    };
}
