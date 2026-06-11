{ self, ... }:

{
  flake.nixosModules.server = {
    imports = [
      self.nixosModules.baseUser
      self.nixosModules.mosh
      self.nixosModules.nixCommon
      self.nixosModules.nukeDefaultPackages
      self.nixosModules.serverBase
      self.nixosModules.serverNix
      self.nixosModules.serverSsh
      self.nixosModules.serverTailscale
    ];
  };
}
