{inputs, ...}: {
  # feuille, the PDF editor (github:sachahjkl/feuille): opens a PDF at once,
  # arranges its pages, puts text on them. Its package installs feuille.desktop
  # and its hicolor icons.
  flake.nixosModules.feuille = {
    lib,
    pkgs,
    ...
  }: {
    environment.systemPackages = [
      inputs.feuille.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    # A host with feuille opens PDFs with it; qpdfview (mimeapps) stays the
    # reader of the hosts without it, and of PostScript and DjVu.
    xdg.mime.defaultApplications."application/pdf" = lib.mkOverride 90 "feuille.desktop";
  };
}
