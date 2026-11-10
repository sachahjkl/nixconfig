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
      self.nixosModules.papier
      self.nixosModules.classeur
      self.nixosModules.shojiwm
      self.nixosModules.gaming
      self.nixosModules.mt7927
      self.nixosModules.house-desktop-hardware
    ];

    gaming.steam.gamescopeSession.enable = true;
    gaming.streaming.sunshine = {
      enable = true;
      autoStart = false;
      cudaSupport = true;
    };
    programs.corectrl.enable = true;

    # scx_lavd gives priority to latency-sensitive tasks, such as games,
    # the compositor, and audio, when background work loads the CPU.
    services.scx = {
      enable = true;
      scheduler = "scx_lavd";
    };

    ai.codex.enable = false;

    # This machine is faster than homelab, and homelab runs other services.
    # Build locally instead of on the homelab build machine from the workstation module.
    nix.distributedBuilds = false;

    shojiwm = {
      enable = true;
      checkout = "${config.homeDirectory}/Projects/shojiwm-win7";
      greeter = {
        enable = true;
        mainScreen = "HDMI-A-1";
        defaultSession = "shojiwm-uwsm";
      };
    };

    git.signingKey = "~/.ssh/far-from-home.pub";
    ssh.identityKey = "~/.ssh/far-from-home";

    terminal.default = "ghostty";

    display = {
      defaultSession = "hyprland-uwsm";
    };

    hyprland = {
      numLock.defaultState = true;
      display.monitors = [
        {
          output = "DP-2";
          mode = "2560x1440@180";
          position = "0x0";
          scale = 1.25;
        }
        {
          output = "HDMI-A-1";
          mode = "3840x2160@60";
          position = "2048x0";
          scale = 1.875;
          colorManagement = "srgb";
          hdr = false;
        }
      ];
    };

    services.xserver.videoDrivers = ["nvidia"];

    boot.kernelParams = [
      "nvidia_drm.fbdev=1"
      # The LG loses the signal when the console starts it directly in 4K,
      # because HDMI 2.0 scrambling fails this early. Start the console in
      # 1080p. Hyprland then sets 4K, and this change works.
      "video=HDMI-A-1:1920x1080@60"
    ];
  };
}
