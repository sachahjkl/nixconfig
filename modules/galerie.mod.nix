{inputs, ...}: {
  # galerie, the image viewer (github:sachahjkl/galerie): a folder at a glance, each
  # picture large and sharp, its details beside it. Its package installs
  # galerie.desktop and its hicolor icons.
  flake.nixosModules.galerie = {pkgs, ...}: {
    environment.systemPackages = [
      inputs.galerie.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
