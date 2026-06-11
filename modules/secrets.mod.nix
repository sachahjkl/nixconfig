{inputs, ...}: {
  flake.nixosModules.secrets = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkDefault mkIf mkMerge;
    inherit (lib.modules) mkAliasOptionModule;
    hasMediaKeyIdentity = builtins.any (path: lib.hasPrefix "/media/key/" path) config.age.identityPaths;
  in {
    imports = [
      inputs.agenix.nixosModules.default
      (mkAliasOptionModule ["secrets"] ["age" "secrets"])
    ];

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
