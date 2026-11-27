{inputs, ...}: {
  # plume, the text editor (github:sachahjkl/plume): code and prose in a window
  # that never waits. Its package installs plume.desktop and its hicolor icons.
  flake.nixosModules.plume = {pkgs, ...}: {
    environment.systemPackages = [
      inputs.plume.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
