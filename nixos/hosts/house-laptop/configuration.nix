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
      self.diskoConfigurations.house-laptop


      self.nixosModules.workstation
      self.nixosModules.niri
      self.nixosModules.mt7927
      self.nixosModules.house-laptop-hardware
    ];

    networking.hostName = "house-laptop";

    preferences.kitty.useThemeColors = false;

    boot.kernelParams = [
      "nvme_core.default_ps_max_latency_us=0"
      "snd-intel-dspcfg.dsp_driver=1"
    ];

    system.autoUpgrade = {
      enable = true;
      flake = "${config.nixConfigPath}#house-laptop";
      dates = "daily";
      randomizedDelaySec = "45min";
    };
  };
}
