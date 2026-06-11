{ self, ... }:

{
  flake.nixosModules.homelab = {
    imports = [
      self.nixosModules.server
      self.nixosModules.homelabLayout
      self.nixosModules.homelabContainers
      self.nixosModules.homelabShares
      self.nixosModules.homelabBackup
      self.nixosModules.homelabSops
      self.nixosModules.homelabProxy
      self.nixosModules.hermesDashboard
      self.nixosModules.sachaHouseService
    ];
  };
}
