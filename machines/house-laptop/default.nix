{ config, ... }: {
  networking.hostName = "house-laptop";

  boot.kernelParams = [
    "nvme_core.default_ps_max_latency_us=0"
    "snd-intel-dspcfg.dsp_driver=1"
  ];

  system.autoUpgrade = {
    enable = true;
    flake = "/home/sacha/Devel/dotfiles#house-laptop";
    dates = "daily";
    randomizedDelaySec = "45min";
  };
}
