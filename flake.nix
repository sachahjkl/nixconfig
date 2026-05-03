{
  description = "NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # aerothemeplasma-nix.url = "github:nyakase/aerothemeplasma-nix";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-conf-editor.url = "github:snowfallorg/nixos-conf-editor";
    mt7927.url = "github:noaccOS/mt7927-nixos/push-nstmptpzyqls";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, nixpkgs-unstable, agenix, home-manager, ... }:
    let
      mkNixosConfig =
        { hardwareConfig, machineConfig }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            pkgs-unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
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
                pkgs-unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
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
