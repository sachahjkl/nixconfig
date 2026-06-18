{lib, ...}: {
  flake.nixosModules.serverNix = {
    config,
    pkgs,
    ...
  }: let
    lixPkgs =
      if config.useLix == "no"
      then null
      else pkgs.lixPackageSets.${config.useLix};
  in {
    config = {
      environment.systemPackages = with pkgs; [
        alejandra
        (lib.nix.selectLixPackage lixPkgs colmena "colmena")
        deadnix
        manix
        (lib.nix.selectLixPackage lixPkgs nil "nil")
        nix-inspect
        (lib.nix.selectLixPackage lixPkgs nix-init "nix-init")
        nix-output-monitor
        nix-tree
        nixd
        nixpkgs-fmt
        statix
      ];
    };
  };
}
