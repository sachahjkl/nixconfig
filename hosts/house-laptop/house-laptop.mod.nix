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
      self.nixosModules.hyprland
      self.nixosModules.mt7927
      self.nixosModules.house-laptop-hardware
    ];

    git.signingKey = "~/.ssh/far-from-home.pub";
    ssh.identityKey = "~/.ssh/far-from-home";
    terminal = {
      default = "ghostty";
      ghostty.theme = self.lib.terminalThemes.kittyDefault;
    };

    display = {
      autoLoginUser = config.userName;
      defaultSession = "hyprland-uwsm";
    };
    hyprland = {
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
