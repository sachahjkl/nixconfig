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
      self.nixosModules.gaming
      self.nixosModules.mt7927
      self.nixosModules.house-desktop-hardware
    ];

    gaming.steam.gamescopeSession.enable = true;
    programs.corectrl.enable = true;

    ai.codex.enable = false;

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

    hyprland.numLock.defaultState = true;

    services.xserver.videoDrivers = ["nvidia"];

    boot.kernelParams = ["nvidia_drm.fbdev=1"];

    system.autoUpgrade = {
      enable = true;
      flake = "${config.nixConfigPath}#house-desktop";
      dates = "daily";
      randomizedDelaySec = "45min";
    };
  };
}
