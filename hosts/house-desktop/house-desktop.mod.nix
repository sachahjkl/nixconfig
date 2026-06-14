{
  self,
  lib,
  ...
}:
lib.systems.nixosSystem "house-desktop" {
  module = {config, ...}: {
    imports = [
      self.diskoConfigurations.house-desktop
      self.nixosModules.workstation
      self.nixosModules.hyprland
      self.nixosModules.niri
      self.nixosModules.gaming
      self.nixosModules.mt7927
      self.nixosModules.house-desktop-hardware
    ];

    gaming.steam.gamescopeSession.enable = true;
    programs.corectrl.enable = true;

    preferences = {
      hyprland.numLock.defaultState = true;
      kitty.useThemeColors = false;
    };

    services.xserver.videoDrivers = ["nvidia"];

    boot.kernelParams = ["nvidia_drm.fbdev=1"];

    hardware = {
      graphics.enable = true;

      nvidia = {
        modesetting.enable = true;
        nvidiaSettings = true;
        open = true;
        nvidiaPersistenced = true;
        powerManagement.enable = true;
      };

      mediatek-mt7927 = {
        enable = true;
        enableWifi = true;
        enableBluetooth = true;
        disableAspm = true;
      };
    };

    system.autoUpgrade = {
      enable = true;
      flake = "${config.nixConfigPath}#house-desktop";
      dates = "daily";
      randomizedDelaySec = "45min";
    };
  };
}
