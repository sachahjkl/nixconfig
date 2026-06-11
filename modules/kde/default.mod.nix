{self, ...}: {
  flake.nixosModules.kde = {
    imports = [
      self.nixosModules.kdeCore
    ];
  };
}
