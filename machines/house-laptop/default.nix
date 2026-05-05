{ config, ... }: {
  desktop.environment = "kde";

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
}
