{inputs, ...}: {
  # feuille, the PDF editor (github:sachahjkl/feuille): opens a PDF at once,
  # arranges its pages, puts text on them. Its package installs feuille.desktop
  # and its hicolor icons.
  flake.nixosModules.feuille = {pkgs, ...}: {
    environment.systemPackages = [
      inputs.feuille.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
