{ inputs, self, ... }:

{
  flake.nixosConfigurations.house-desktop = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs self;
      pkgs-hyprnix = inputs.hyprnix.packages.x86_64-linux;
    };
    modules = [ self.nixosModules.house-desktop ];
  };

  flake.nixosModules.house-desktop = { pkgs, config, lib, self, ... }: {
    imports = [
      self.nixosModules.disko
      self.nixosModules.external-preservation
      self.nixosModules.helium
      self.nixosModules.hjem
      self.nixosModules.mt7927
      self.nixosModules.common
      self.nixosModules.base
      self.nixosModules.wallpaper
      self.nixosModules.face-icon
      self.nixosModules.desktop
      self.nixosModules.hyprlandCore
      self.nixosModules.hyprlandPackages
      self.nixosModules.hyprlandConfig
      self.nixosModules.hyprlandLock
      self.nixosModules.hyprlandWaybar
      self.nixosModules.hyprlandDunst
      self.nixosModules.hyprlandApps
      self.nixosModules.hyprlandScripts
      self.nixosModules.niri
      self.nixosModules.packages
      self.nixosModules.preservation
      self.nixosModules.shell
      self.nixosModules.sacha-hjem
      self.nixosModules.sacha-user
      self.nixosModules.gaming
      self.nixosModules.house-desktop-hardware
    ];

    desktop.environment = "both";
    gaming.steam.gamescopeSession.enable = true;
    programs.corectrl.enable = true;

    networking.hostName = "house-desktop";

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
      flake = "${config.sacha.dotfilesPath}#house-desktop";
      dates = "daily";
      randomizedDelaySec = "45min";
    };
  };
}
