_: {
  flake.nixosModules.face-icon = {lib, ...}: {
    config.assets.faceIcon = lib.mkDefault ./face.icon;
  };
}
