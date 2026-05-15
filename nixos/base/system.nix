{ lib, ... }:

{
  flake.nixosModules.base = { config, pkgs, ... }: {
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
    services.flatpak.enable = true;
    services.gnome.gnome-keyring.enable = true;
    services.gnome.gcr-ssh-agent.enable = false;
    programs.ssh.startAgent = true;

    programs.nix-ld.enable = true;
    programs.appimage.enable = true;
    programs.appimage.binfmt = true;
    programs.nh = {
      enable = true;
      flake = config.sacha.dotfilesPath;
    };

    security.sudo.wheelNeedsPassword = false;
    security.sudo.execWheelOnly = true;

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

    nixpkgs.config.allowUnfree = true;
    # Required by pkgs.sublime4; remove once Sublime stops depending on OpenSSL 1.1.
    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.1.1w"
    ];

    hardware.enableRedistributableFirmware = true;

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    system.stateVersion = "26.05";

    nix.settings = {
      accept-flake-config = true;
      experimental-features = [ "nix-command" "flakes" ];
      download-buffer-size = "100M";
      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://cache.nixos.org"
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
}
