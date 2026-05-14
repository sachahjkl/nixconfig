{ ... }:

{
  flake.nixosModules.wallpaper = { lib, ... }: {
    config.sacha.assets.wallpaper = lib.mkDefault ./wallpaper.jpg;
  };
}
