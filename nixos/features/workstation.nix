{ self, ... }:

{
  flake.nixosModules.workstation = {
    imports = [
      self.nixosModules.base
      self.nixosModules.base-assets
      self.nixosModules.desktop
      self.nixosModules.disko
      self.nixosModules.external-preservation
      self.nixosModules.fish
      self.nixosModules.hjem
      self.nixosModules.lf
      self.nixosModules.neovim
      self.nixosModules.nix
      self.nixosModules.packages
      self.nixosModules.preservation
      self.nixosModules.user-home
      self.nixosModules.ssh
      self.nixosModules.steam
      self.nixosModules.sublime
      self.nixosModules.zoxide
    ];
  };
}
