{ inputs, ... }:

{
  flake.nixosModules = {
    disko = inputs.disko.nixosModules.disko;
    external-preservation = inputs.preservation.nixosModules.preservation;
    hjem = inputs.hjem.nixosModules.default;
    mt7927 = inputs.mt7927.nixosModules.default;
  };
}
