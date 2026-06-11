{ inputs, self, lib, ... }:
lib.systems.nixosSystem "house-desktop" {
  extraSpecialArgs = {
    pkgs-hyprnix = inputs.hyprnix.packages.x86_64-linux;
  };

  module = { config, ... }: {
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

    preferences.kitty.useThemeColors = false;

    age.identityPaths = [ "/home/sacha/.ssh/agenix" ];
    secrets.userPasswordHashAgeFile = ./user-password-hash.age;

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.graphics.enable = true;

    hardware.nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      open = true;
      nvidiaPersistenced = true;
      powerManagement.enable = true;
    };

    boot.kernelParams = [ "nvidia_drm.fbdev=1" ];

    hardware.mediatek-mt7927 = {
      enable = true;
      enableWifi = true;
      enableBluetooth = true;
      disableAspm = true;
    };

    system.autoUpgrade = {
      enable = true;
      flake = "${config.nixConfigPath}#house-desktop";
      dates = "daily";
      randomizedDelaySec = "45min";
    };
  };
}
