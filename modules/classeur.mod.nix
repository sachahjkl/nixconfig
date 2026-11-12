{inputs, ...}: {
  # Classeur, the file manager (github:sachahjkl/classeur). Its package
  # installs classeur.desktop (StartupWMClass=classeur, MimeType=inode/directory)
  # and its hicolor icons.
  flake.nixosModules.classeur = {pkgs, ...}: {
    environment.systemPackages = [
      inputs.classeur.packages.${pkgs.stdenv.hostPlatform.system}.default
      # The thumbnailers classeur asks for PDF and video previews
      # (share/thumbnailers/*.thumbnailer, the freedesktop standard).
      pkgs.papers
      pkgs.ffmpegthumbnailer
    ];
    environment.pathsToLink = ["/share/thumbnailers"];
  };
}
