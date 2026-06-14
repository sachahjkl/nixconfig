{self, ...}: {
  flake.nixosModules.server = {lib, ...}: {
    imports = [
      self.nixosModules.baseUser
      self.nixosModules.external-preservation
      self.nixosModules.hjem
      self.nixosModules.home-manager
      self.nixosModules.mosh
      self.nixosModules.nixCommon
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

    preferences.userHome.installTerminal = lib.mkDefault false;
  };
}
