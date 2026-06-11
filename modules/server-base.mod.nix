{ ... }:

{
  flake.nixosModules.serverBase = { pkgs, ... }: {
    config = {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.kernelPackages = pkgs.linuxPackages_latest;
      boot.supportedFilesystems = [ "btrfs" "ext4" "nfs" "vfat" ];

      networking.useNetworkd = true;
      systemd.network.enable = true;
      services.resolved.enable = true;

      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
        publish = {
          enable = true;
          userServices = true;
          workstation = true;
        };
      };

      services.btrfs.autoScrub = {
        enable = true;
        interval = "monthly";
      };

      services.fstrim.enable = true;
      services.smartd.enable = true;

      programs.fish.enable = true;

      users.mutableUsers = false;

      security.sudo.wheelNeedsPassword = false;
      security.sudo.execWheelOnly = true;

      time.timeZone = "Europe/Paris";

      i18n.defaultLocale = "en_US.UTF-8";
      i18n.extraLocaleSettings = {
        LC_ADDRESS = "fr_FR.UTF-8";
        LC_IDENTIFICATION = "fr_FR.UTF-8";
        LC_MEASUREMENT = "fr_FR.UTF-8";
        LC_MONETARY = "fr_FR.UTF-8";
        LC_NAME = "fr_FR.UTF-8";
        LC_NUMERIC = "fr_FR.UTF-8";
        LC_PAPER = "fr_FR.UTF-8";
        LC_TELEPHONE = "fr_FR.UTF-8";
        LC_TIME = "fr_FR.UTF-8";
      };

      console.keyMap = "fr";

      environment.systemPackages = with pkgs; [
        curl
        git
        htop
        jq
        lm_sensors
        lsof
        ncdu
        restic
        smartmontools
        tmux
        vim
        wget
      ];

      services.journald.extraConfig = ''
        SystemMaxUse=1G
      '';

      hardware.enableRedistributableFirmware = true;

      system.stateVersion = "26.05";
    };
  };
}
