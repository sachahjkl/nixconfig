{ pkgs, ... }:

{
  # Bootloader — Limine with Secure Boot support.
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.limine.enable = true;
  boot.loader.limine.secureBoot.enable = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "quiet"
    "splash"
    # Disable NVMe APST entirely to avoid the Kingston boot error on this machine.
    "nvme_core.default_ps_max_latency_us=0"
    # Force the legacy Intel HDA driver instead of the newer AVS DSP stack.
    "snd-intel-dspcfg.dsp_driver=1"
  ];
  boot.plymouth.enable = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  services.fstrim.enable = true;
  services.fwupd.enable = true;
  services.flatpak.enable = true;

  programs.nix-ld.enable = true;

  security.sudo.wheelNeedsPassword = false;
  security.sudo.execWheelOnly = true;

  system.autoUpgrade = {
    enable = true;
    flake = "/home/sacha/nixos-flake-setup";
    dates = "daily";
    randomizedDelaySec = "45min";
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  virtualisation.libvirtd.enable = true;
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
    font = "Lat2-Terminus16";
    keyMap = "fr";
    packages = [ pkgs.terminus_font ];
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  hardware.enableRedistributableFirmware = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "@wheel" ];
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  system.stateVersion = "25.11";
}
