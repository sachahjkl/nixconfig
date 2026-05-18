{ lib, ... }:

{
  flake.nixosModules.base = { config, pkgs, ... }: {
    options.nixConfigPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/sacha/Projects/nixconfig";
      description = "Local path to this Nix flake checkout.";
    };

    config = {
      # Bootloader — Limine with Secure Boot support.
      boot.loader.systemd-boot.enable = false;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.limine.enable = true;
      boot.loader.limine.secureBoot.enable = true;

      # Use latest kernel.
      boot.kernelPackages = pkgs.linuxPackages_latest;
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
      boot.kernelParams = [
        "quiet"
        "splash"
        "pcie_aspm=off"
      ];
      boot.supportedFilesystems.ntfs = true;
      boot.plymouth.enable = true;

      networking.networkmanager.enable = true;

      services.pcscd.enable = true;
      services.fstrim.enable = true;
      services.fwupd.enable = true;
      services.gnome.gnome-keyring.enable = true;
      services.gnome.gcr-ssh-agent.enable = false;
      programs.ssh.startAgent = true;

      programs.appimage.enable = true;
      programs.appimage.binfmt = true;

      security.sudo.wheelNeedsPassword = false;
      security.sudo.execWheelOnly = true;
      security.sudo.extraConfig = ''
        Defaults env_reset,pwfeedback
      '';

      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };

      virtualisation.libvirtd.enable = true;
      systemd.services.libvirtd.serviceConfig.LoadCredential = lib.mkForce "";
      virtualisation.spiceUSBRedirection.enable = true;
      programs.virt-manager.enable = true;

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

      console = {
        earlySetup = true;
        font = "ter-v32b";
        keyMap = "fr";
        packages = [ pkgs.terminus_font ];
      };

      hardware.enableRedistributableFirmware = true;

      system.stateVersion = "26.05";
    };
  };
}
