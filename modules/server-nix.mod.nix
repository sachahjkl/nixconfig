_: {
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
        (
          if lixPkgs == null
          then colmena
          else lixPkgs.colmena
        )
        deadnix
        manix
        (
          if lixPkgs == null
          then nil
          else lixPkgs.nil
        )
        nix-inspect
        (
          if lixPkgs == null
          then nix-init
          else lixPkgs.nix-init
        )
        nix-output-monitor
        nix-tree
        nixd
        nixpkgs-fmt
        statix
      ];
    };
  };
}
