{self, ...}: {
  flake.nixosModules.workstation = {
    imports = [
      self.nixosModules.baseUser
      self.nixosModules.baseAssets
      self.nixosModules.baseSystem
      self.nixosModules.ai
      self.nixosModules.desktop
      self.nixosModules.disko
      self.nixosModules.external-preservation
      self.nixosModules.fish
      self.nixosModules.home-manager
      self.nixosModules.hjem
      self.nixosModules.lf
      self.nixosModules.mosh
      self.nixosModules.neovim
      self.nixosModules.nix
      self.nixosModules.nixCommon
      self.nixosModules.nukeDefaultPackages
      self.nixosModules.opencode
      self.nixosModules.packages
      self.nixosModules.desktop-packages
      self.nixosModules.preservation
      self.nixosModules.user-home
      self.nixosModules.xdgStubs
      self.nixosModules.ssh
      self.nixosModules.steam
      self.nixosModules.sublime
      self.nixosModules.tailscale
      self.nixosModules.vscode
      self.nixosModules.zoxide
    ];

    features.ai.enable = true;
    features.steam.enable = true;
  };
}
