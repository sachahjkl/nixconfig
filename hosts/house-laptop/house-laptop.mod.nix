{
  self,
  lib,
  ...
}:
lib.systems.nixosSystem "house-laptop" {
  module = {config, ...}: {
    imports = [
      self.diskoConfigurations.house-laptop
      self.nixosModules.workstation
      self.nixosModules.ghostty
      self.nixosModules.hyprland
      self.nixosModules.mt7927
      self.nixosModules.house-laptop-hardware
    ];

    features.ghostty.enable = true;

    preferences.kitty.useThemeColors = false;
    preferences.hyprland = {
      numLock.defaultState = false;
      laptopMode.enable = true;
      display = {
        output = "eDP-1";
        scale = 1.25;
      };
    };

    boot.kernelParams = [
      "nvme_core.default_ps_max_latency_us=0"
    ];

    hardware.enableAllFirmware = true;

    system.autoUpgrade = {
      enable = true;
      flake = "${config.nixConfigPath}#house-laptop";
      dates = "daily";
      randomizedDelaySec = "45min";
    };
  };
}
