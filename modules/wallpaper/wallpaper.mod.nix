_: {
  flake.nixosModules.wallpaper = {lib, ...}: {
    config.assets.wallpaper = lib.mkDefault (builtins.path {
      path = ./wallpaper.jpg;
      name = "wallpaper.jpg";
    });
  };
}
