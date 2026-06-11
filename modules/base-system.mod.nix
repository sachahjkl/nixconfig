{lib, ...}: {
  flake.nixosModules.baseSystem = {pkgs, ...}: {
    config = {
      boot = {
        loader = {
          systemd-boot.enable = false;
          efi.canTouchEfiVariables = true;
          limine = {
            enable = true;
            secureBoot.enable = true;
          };
        };
        kernelPackages = pkgs.linuxPackages_latest;
        binfmt.emulatedSystems = ["aarch64-linux"];
        kernel.sysctl."fs.inotify.max_user_watches" = 524288;
        kernelParams = [
          "quiet"
          "splash"
          "pcie_aspm=off"
        ];
        supportedFilesystems.ntfs = true;
        plymouth.enable = true;
      };

      networking.networkmanager.enable = true;

      services = {
        pcscd.enable = true;
        fstrim.enable = true;
        fwupd.enable = true;
        gnome = {
          gnome-keyring.enable = true;
          gcr-ssh-agent.enable = false;
        };
      };

      programs = {
        ssh.startAgent = true;
        appimage = {
          enable = true;
          binfmt = true;
        };
        virt-manager.enable = true;
      };

      extraUserGroups = ["networkmanager" "audio" "video" "podman" "libvirtd" "kvm"];

      security.sudo = {
        wheelNeedsPassword = false;
        execWheelOnly = true;
        extraConfig = ''
          Defaults env_reset,pwfeedback
        '';
      };

      virtualisation = {
        podman = {
          enable = true;
          dockerCompat = true;
          defaultNetwork.settings.dns_enabled = true;
        };
        libvirtd.enable = true;
        spiceUSBRedirection.enable = true;
      };

      systemd.services.libvirtd.serviceConfig.LoadCredential = lib.mkForce "";

      time.timeZone = "Europe/Paris";

      i18n = {
        defaultLocale = "en_US.UTF-8";
        extraLocaleSettings = {
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
      };

      console = {
        earlySetup = true;
        font = "ter-v32b";
        keyMap = "fr";
        packages = [pkgs.terminus_font];
      };

      hardware.enableRedistributableFirmware = true;

      system.stateVersion = "26.05";
    };
  };
}
