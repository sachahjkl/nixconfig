{inputs, ...}: {
  # socle, a NixOS or Home Manager system in one window
  # (github:sachahjkl/socle). Its program only, not its NixOS module: socle
  # owns the configuration of a machine it takes over, and this one's is this
  # flake. Here it opens on its demo (socle --demo) or on a home
  # (socle --home); nothing changes until a person applies.
  flake.nixosModules.socle = {pkgs, ...}: {
    environment.systemPackages = [
      inputs.socle.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
