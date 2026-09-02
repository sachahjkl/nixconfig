{self, ...}: {
  flake.nixosModules.server = {...}: {
    imports = [
      self.nixosModules.baseUser
      self.nixosModules.external-preservation
      self.nixosModules.editor
      self.nixosModules.fish
      self.nixosModules.hjem
      self.nixosModules.home-manager
      self.nixosModules.kernelHardening
      self.nixosModules.mosh
      self.nixosModules.moshiHook
      self.nixosModules.nixCommon
      self.nixosModules.neovim
      self.nixosModules.nukeDefaultPackages
      self.nixosModules.opencode
      self.nixosModules.packages
      self.nixosModules.preservation
      self.nixosModules.sharedSops
      self.nixosModules.serverBase
      self.nixosModules.ssh
      self.nixosModules.user-home
      self.nixosModules.serverNix
      self.nixosModules.serverSsh
      self.nixosModules.serverTailscale
    ];

    moshi.enable = true;
  };
}
