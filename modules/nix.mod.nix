{
  inputs,
  lib,
  ...
}: {
  flake.nixosModules.nix = {
    config,
    pkgs,
    ...
  }: let
    lixPkgs =
      if config.useLix == "no"
      then null
      else pkgs.lixPackageSets.${config.useLix};
  in {
    imports = [
      inputs.nix-index-database.nixosModules.nix-index
    ];

    programs = {
      nix-index-database.comma.enable = true;
      nix-ld.enable = true;
    };

    environment.systemPackages = with pkgs; [
      alejandra
      cachix
      deadnix
      manix
      (lib.nix.selectLixPackage lixPkgs nil "nil")
      nix-inspect
      (lib.nix.selectLixPackage lixPkgs nix-init "nix-init")
      nix-melt
      nix-output-monitor
      nix-prefetch
      nix-tree
      nixd
      nixpkgs-fmt
      statix
    ];

    hjem.users.${config.userName}.rum.programs.direnv = {
      enable = true;
      settings = {
        global.warn_timeout = "0s";
      };
      integrations = {
        fish.enable = true;
        nix-direnv.enable = true;
      };
    };

    persist.user.directories = [".local/share/direnv"];
  };
}
