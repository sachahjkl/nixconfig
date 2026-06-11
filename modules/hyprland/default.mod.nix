{ self, ... }:

{
  flake.nixosModules.hyprland = {
    imports = [
      self.nixosModules.hyprlandCore
      self.nixosModules.hyprlandPackages
      self.nixosModules.hyprlandConfig
      self.nixosModules.hyprlandLock
      self.nixosModules.hyprlandWaybar
      self.nixosModules.hyprlandDunst
      self.nixosModules.hyprlandApps
      self.nixosModules.hyprlandScripts
    ];
  };
}
