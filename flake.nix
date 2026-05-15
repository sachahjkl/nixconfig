{
  description = "Sacha's NixOS system configuration";

  nixConfig = {
    auto-optimise-store = true;
    builders-use-substitutes = true;
    download-buffer-size = "100M";
    extra-experimental-features = [ "flakes" "nix-command" "pipe-operators" ];
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    flake-registry = "";
    http-connections = 50;
    show-trace = true;
    trusted-users = [ "root" "@wheel" ];
    use-xdg-base-directories = true;
    warn-dirty = false;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation.url = "github:nix-community/preservation";

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wrappers.url = "github:Lassulus/wrappers";
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    nh = {
      url = "github:nix-community/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-fast-build = {
      url = "github:Mic92/nix-fast-build";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-conf-editor.url = "github:snowfallorg/nixos-conf-editor";
    mt7927.url = "github:cmspam/mt7927-nixos";
    hyprnix.url = "github:hyprwm/hyprnix";
  };

  outputs = inputs:
    let
      inherit (inputs.nixpkgs) lib;
      inherit (lib.fileset) fileFilter toList;

      isFlakePart = file:
        file.hasExt "nix"
        && file.name != "flake.nix"
        && !lib.hasPrefix "_" file.name;

      importTree = path: toList (fileFilter isFlakePart path);
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = importTree ./.;
    };
}
