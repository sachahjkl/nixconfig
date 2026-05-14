{ ... }:

{
  flake.nixosModules.face-icon = { lib, ... }: {
    config.sacha.assets.faceIcon = lib.mkDefault ./face.icon;
  };
}
