{
  description = "NixOS system configuration";

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
    # aerothemeplasma-nix.url = "github:nyakase/aerothemeplasma-nix";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-conf-editor.url = "github:snowfallorg/nixos-conf-editor";
    mt7927.url = "github:noaccOS/mt7927-nixos/push-nstmptpzyqls";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium.url = "gitlab:ntgn/helium-flake";
    hyprnix.url = "github:hyprwm/hyprnix";
  };

  outputs = inputs@{ nixpkgs, agenix, home-manager, helium, hyprnix, ... }:
    let
      mkNixosConfig =
        { hardwareConfig, machineConfig }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            pkgs-hyprnix = hyprnix.packages.x86_64-linux;
          };
          modules = [
            hardwareConfig
            machineConfig
            inputs.mt7927.nixosModules.default
            ./configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs;
                pkgs-hyprnix = hyprnix.packages.x86_64-linux;
              };
              home-manager.users.sacha = import ./users/sacha/home.nix;
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        house-laptop = mkNixosConfig {
          hardwareConfig = ./machines/house-laptop/hardware-configuration.nix;
          machineConfig = ./machines/house-laptop;
        };
        house-desktop = mkNixosConfig {
          hardwareConfig = ./machines/house-desktop/hardware-configuration.nix;
          machineConfig = ./machines/house-desktop;
        };
      };
    };
}
