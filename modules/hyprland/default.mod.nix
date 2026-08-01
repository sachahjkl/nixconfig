{self, ...}: {
  flake.nixosModules.hyprland = {
    config,
    pkgs,
    ...
  }: {
    imports = [
      self.nixosModules.powerMenu
      self.nixosModules.hyprlandCore
      self.nixosModules.hyprlandPackages
      self.nixosModules.hyprlandConfig
      self.nixosModules.hyprlandLock
      self.nixosModules.hyprlandWaybar
      self.nixosModules.hyprlandDunst
      self.nixosModules.hyprlandApps
    ];

    powerMenu.rofiPackage = self.lib.mkRofi {
      inherit pkgs;
      theme = config.theme.rofiTheme;
    };
  };
}
