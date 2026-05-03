{ pkgs, config, lib, ... }: {
  networking.hostName = "house-desktop";

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
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
    flake = "/home/sacha/Devel/dotfiles#house-desktop";
    dates = "daily";
    randomizedDelaySec = "45min";
  };
}
