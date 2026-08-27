_: {
  flake.nixosModules.face-icon = {lib, ...}: {
    config.assets.faceIcon = lib.mkDefault (builtins.path {
      path = ./face.icon;
      name = "face.icon";
    });
  };
}
