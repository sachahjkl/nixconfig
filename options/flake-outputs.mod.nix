{
  inputs,
  lib,
  ...
}: {
  config.flake.nixosModules = {
    disko = inputs.disko.nixosModules.disko;
    external-preservation = inputs.preservation.nixosModules.preservation;
    home-manager = inputs.home-manager.nixosModules.home-manager;
    hjem = inputs.hjem.nixosModules.default;
    mt7927 = inputs.mt7927.nixosModules.default;
    sops = inputs.sops-nix.nixosModules.sops;
  };

  options.flake.lib = lib.mkOption {
    type = lib.types.attrs;
    default = {};
    description = "Library functions exposed by the flake.";
  };
}
