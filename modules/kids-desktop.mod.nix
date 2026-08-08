{self, ...}: {
  flake.nixosModules.kidsDesktop = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.kidsDesktop.games;
  in {
    imports = [
      self.nixosModules.kidsAccounts
      self.nixosModules.kidsNetwork
      self.nixosModules.kidsShares
    ];

    options.kidsDesktop.games = {
      education.enable = lib.mkEnableOption "educational games" // {default = true;};
      family.enable = lib.mkEnableOption "family games" // {default = true;};
      minecraft.enable = lib.mkEnableOption "Minecraft and Luanti launchers" // {default = true;};
      retro.enable = lib.mkEnableOption "RetroArch" // {default = true;};
      steam.enable = lib.mkEnableOption "Steam" // {default = true;};
    };

    config = {
      boot = {
        loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };
        kernelPackages = pkgs.linuxPackages_latest;
      };

      networking = {
        networkmanager.enable = true;
        firewall.enable = true;
      };

      services = {
        accounts-daemon.enable = true;
        avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };
        blueman.enable = true;
        fstrim.enable = true;
        fwupd.enable = true;
        gvfs.enable = true;
        printing.enable = true;
        pulseaudio.enable = false;
        pipewire = {
          enable = true;
          alsa = {
            enable = true;
            support32Bit = true;
          };
          pulse.enable = true;
        };
        xserver = {
          enable = true;
          desktopManager.cinnamon.enable = true;
          displayManager.lightdm.enable = true;
          xkb.layout = "fr";
        };
      };

      hardware = {
        bluetooth = {
          enable = true;
          powerOnBoot = true;
        };
        enableRedistributableFirmware = true;
        graphics.enable = true;
      };

      programs = {
        firefox = {
          enable = true;
          policies.DNSOverHTTPS.Enabled = false;
        };
        gamemode.enable = true;
        steam.enable = cfg.steam.enable;
      };

      environment.systemPackages =
        (with pkgs; [
          file-roller
          gthumb
          hunspell
          hunspellDicts.en-us
          hunspellDicts.fr-any
          libreoffice
          vlc
        ])
        ++ lib.optionals cfg.education.enable (with pkgs; [gcompris])
        ++ lib.optionals cfg.family.enable (with pkgs; [
          supertux
          supertuxkart
        ])
        ++ lib.optionals cfg.minecraft.enable (with pkgs; [
          luanti
          prismlauncher
        ])
        ++ lib.optionals cfg.retro.enable [pkgs."retroarch-full"];

      security = {
        polkit.enable = true;
        rtkit.enable = true;
      };

      nix = {
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 14d";
        };
        optimise.automatic = true;
        settings.experimental-features = [
          "flakes"
          "nix-command"
        ];
      };

      nixpkgs.config.allowUnfree = true;

      time.timeZone = "Europe/Paris";

      i18n = {
        defaultLocale = "fr_FR.UTF-8";
        extraLocaleSettings.LC_TIME = "fr_FR.UTF-8";
      };

      console.keyMap = "fr";
      system.stateVersion = "26.05";
    };
  };
}
