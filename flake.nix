{
  description = "Sacha's NixOS system configuration";

  nixConfig = {
    auto-optimise-store = true;
    builders-use-substitutes = true;
    extra-experimental-features = ["flakes" "nix-command"];
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
    trusted-users = ["root" "@wheel"];
    use-xdg-base-directories = true;
    warn-dirty = false;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      # Need to use the latest commit (18-05-2026 22:50) of the master branch to be able to use 'enrollFido2'
      url = "github:nix-community/disko/d405a179887d52b24c0ddd31e09a150bd1f66779";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation.url = "github:nix-community/preservation";

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hjem-rum = {
      url = "github:snugnug/hjem-rum";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hjem.follows = "hjem";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager/trunk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    wrappers.url = "github:Lassulus/wrappers";
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mt7927.url = "github:cmspam/mt7927-nixos";

    mcp-nixos = {
      url = "github:utensils/mcp-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanblaster = {
      url = "gitlab:sachahjkl/lanblaster.sacha.house";
      flake = false;
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake
    {
      inherit inputs;

      specialArgs.lib = inputs.nixpkgs.lib.extend (
        final: prev:
          inputs.nixpkgs.lib.recursiveUpdate prev (
            import ./lib {
              lib = final;
              inherit inputs;
              inherit (inputs) self;
            }
          )
      );
    }
    ({lib, ...}: let
      inherit (lib.filesystem) listFilesRecursive;
      inherit (lib.lists) filter;
      inherit (lib.strings) hasSuffix;
    in {
      systems = ["x86_64-linux"];

      imports =
        [
          inputs.wrapper-modules.flakeModules.wrappers
          inputs.disko.flakeModules.default
        ]
        ++ filter (path: hasSuffix ".mod.nix" (toString path)) (listFilesRecursive ./.);
    });
}
