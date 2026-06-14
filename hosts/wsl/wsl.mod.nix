{
  inputs,
  self,
  lib,
  ...
}:
lib.systems.nixosSystem "wsl" {
  module = {lib, ...}: {
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
      self.nixosModules.nixCommon
      self.nixosModules.opencode
      self.nixosModules.packages
      self.nixosModules.preservation
      self.nixosModules.sharedSops
      self.nixosModules.ssh
      self.nixosModules.user-home
      self.nixosModules.xdgStubs
    ];

    wsl = {
      enable = true;
      defaultUser = "nixos";
      interop.register = true;
    };

    userName = "nixos";
    fullName = "NixOS";
    homeDirectory = "/home/nixos";
    nixConfigPath = "/home/nixos/Projects/nixconfig";

    preferences = {
      sops = {
        enable = true;
        passwordHashSecretName = "shared/password-hash";
      };

      preservation.enable = lib.mkForce false;
      userHome.installTerminal = false;
    };

    security.pki.certificateFiles = [
      ./certs/zscaler-root-ca.pem
      ./certs/ca-ogfprod-root.pem
    ];

    system.stateVersion = "26.05";
  };
}
