_: {
  flake.nixosModules.serverNix = {pkgs, ...}: {
    config = {
      environment.systemPackages = with pkgs; [
        alejandra
        colmena
        deadnix
        manix
        nil
        nix-inspect
        nix-init
        nix-output-monitor
        nix-tree
        nixd
        nixpkgs-fmt
        statix
      ];
    };
  };
}
