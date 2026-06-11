_: {
  flake.nixosModules.wallpaper = {lib, ...}: {
    config.assets.wallpaper = lib.mkDefault ./wallpaper.jpg;
  };
}
