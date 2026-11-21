{self, ...}: {
  flake.nixosModules.server = {...}: {
    imports = [
      self.nixosModules.common
      self.nixosModules.hardwareWatchdog
      self.nixosModules.kernelHardening
      self.nixosModules.serverBase
      self.nixosModules.serverSsh
      self.nixosModules.serverTailscale
      self.nixosModules.thermalGuard
    ];
  };
}
