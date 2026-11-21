{self, ...}: {
  # Modules shared by every personal host (workstations, servers, and WSL).
  flake.nixosModules.common = {...}: {
    imports = [
      self.nixosModules.ai
      self.nixosModules.baseUser
      self.nixosModules.editor
      self.nixosModules.external-preservation
      self.nixosModules.fish
      self.nixosModules.hjem
      self.nixosModules.lf
      self.nixosModules.mosh
      self.nixosModules.moshiHook
      self.nixosModules.neovim
      self.nixosModules.nix
      self.nixosModules.nixCommon
      self.nixosModules.nukeDefaultPackages
      self.nixosModules.opencode
      self.nixosModules.packages
      self.nixosModules.preservation
      self.nixosModules.sharedSops
      self.nixosModules.ssh
      self.nixosModules.user-home
      self.nixosModules.xdgStubs
      self.nixosModules.zoxide
    ];

    moshi.enable = true;
  };
}
