{ inputs, self, ... }:

{
  flake.nixosConfigurations.house-laptop = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs self;
      pkgs-hyprnix = inputs.hyprnix.packages.x86_64-linux;
    };
    modules = [ self.nixosModules.house-laptop ];
  };

  flake.nixosModules.house-laptop = { config, ... }: {
    imports = [
      self.nixosModules.disko
      self.nixosModules.external-preservation
      self.nixosModules.flatpak
      self.nixosModules.firefox
      self.nixosModules.brave
      self.nixosModules.direnv
      self.nixosModules.fish
      self.nixosModules.hjem
      self.nixosModules.mt7927
      self.nixosModules.neovim
      self.nixosModules.kitty
      self.nixosModules.lf
      self.nixosModules.mimeapps
      self.nixosModules.sublime
      self.nixosModules.obsStudio
      self.nixosModules.base
      self.nixosModules.base-assets
      self.nixosModules.steam
      self.nixosModules.wallpaper
      self.nixosModules.wireplumber
      self.nixosModules.zoxide
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
      self.nixosModules.ssh
      self.nixosModules.house-laptop-hardware
    ];

    desktop.environment = "niri";

    networking.hostName = "house-laptop";

    sacha.kitty.useThemeColors = false;

    boot.kernelParams = [
      "nvme_core.default_ps_max_latency_us=0"
      "snd-intel-dspcfg.dsp_driver=1"
    ];

    system.autoUpgrade = {
      enable = true;
      flake = "${config.sacha.nixConfigPath}#house-laptop";
      dates = "daily";
      randomizedDelaySec = "45min";
    };
  };
}
