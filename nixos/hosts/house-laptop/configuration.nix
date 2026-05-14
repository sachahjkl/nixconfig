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
      self.nixosModules.helium
      self.nixosModules.hjem
      self.nixosModules.mt7927
      self.nixosModules.common
      self.nixosModules.base
      self.nixosModules.wallpaper
      self.nixosModules.face-icon
      self.nixosModules.desktop
      self.nixosModules.hyprland
      self.nixosModules.niri
      self.nixosModules.packages
      self.nixosModules.preservation
      self.nixosModules.shell
      self.nixosModules.sacha-hjem
      self.nixosModules.sacha-user
      ./_hardware.nix
    ];

    desktop.environment = "niri";

    networking.hostName = "house-laptop";

    boot.kernelParams = [
      "nvme_core.default_ps_max_latency_us=0"
      "snd-intel-dspcfg.dsp_driver=1"
    ];

    system.autoUpgrade = {
      enable = true;
      flake = "${config.sacha.dotfilesPath}#house-laptop";
      dates = "daily";
      randomizedDelaySec = "45min";
    };
  };
}
