{inputs, ...}: {
  flake.nixosModules.secrets = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkDefault mkIf mkMerge mkOption;
    inherit (lib.modules) mkAliasOptionModule;
    inherit (lib.types) str;
    hasMediaKeyIdentity = builtins.any (path: lib.hasPrefix "/media/key/" path) config.age.identityPaths;
  in {
    imports = [
      inputs.agenix.nixosModules.default
      (mkAliasOptionModule ["secrets"] ["age" "secrets"])
    ];

    options.preferences.secrets.mediaKeyLabel = mkOption {
      type = str;
      default = "sopskey";
      description = "Filesystem label of the USB media key used for age identities at boot.";
    };

    config = mkMerge [
      {
        age.identityPaths = mkDefault [];
      }

      (mkIf hasMediaKeyIdentity {
        boot.initrd.availableKernelModules = [
          "exfat"
          "usb_storage"
          "uas"
        ];

        fileSystems."/media/key" = {
          device = "/dev/disk/by-label/${config.preferences.secrets.mediaKeyLabel}";
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
