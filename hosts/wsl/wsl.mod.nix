{ inputs, self, lib, ... }:
lib.systems.nixosSystem "wsl" {
  module = { lib, ... }: {
    imports = [
      inputs.nixos-wsl.nixosModules.default
      self.nixosModules.wsl-hardware
      self.nixosModules.baseUser
      self.nixosModules.external-preservation
      self.nixosModules.fish
      self.nixosModules.home-manager
      self.nixosModules.hjem
      self.nixosModules.neovim
      self.nixosModules.nix
      self.nixosModules.opencode
      self.nixosModules.packages
      self.nixosModules.preservation
      self.nixosModules.user-home
      self.nixosModules.xdgStubs
    ];

    wsl.enable = true;
    wsl.defaultUser = "nixos";
    wsl.interop.register = true;

    userName = "nixos";
    fullName = "NixOS";
    homeDirectory = "/home/nixos";
    nixConfigPath = "/home/nixos/Projects/nixconfig";

    secrets.userPasswordHash = "";

    system.stateVersion = "26.05";

    preferences.preservation.enable = lib.mkForce false;
    preferences.userHome.installTerminal = false;
  };
}
