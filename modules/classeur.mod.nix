{inputs, ...}: {
  # Classeur, the file manager (github:sachahjkl/classeur). Its package
  # installs classeur.desktop (StartupWMClass=classeur, MimeType=inode/directory)
  # and its hicolor icons.
  flake.nixosModules.classeur = {pkgs, ...}: {
    environment.systemPackages = [inputs.classeur.packages.${pkgs.stdenv.hostPlatform.system}.default];
  };
}
