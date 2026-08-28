{
  self,
  lib,
  ...
}:
lib.systems.nixosSystem "homelab-rescue" {
  module = {pkgs, ...}: {
    boot = {
      initrd.availableKernelModules = ["xhci_pci" "usb_storage" "uas" "sd_mod" "nvme"];
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        timeout = 10;
      };
      supportedFilesystems = ["btrfs" "vfat"];
    };

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/2d856b6e-e4bf-410e-af31-a640924a8bff";
        fsType = "btrfs";
        options = ["subvol=@nixos-rescue" "compress=zstd" "noatime"];
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/1E38-F67E";
        fsType = "vfat";
        options = ["umask=0077"];
      };
    };

    networking = {
      useDHCP = false;
      useNetworkd = true;
    };

    systemd.network = {
      enable = true;
      networks."10-lan" = {
        matchConfig.Name = "eno1";
        networkConfig.DHCP = "yes";
        linkConfig.RequiredForOnline = "routable";
      };
    };

    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };

    users.users.root.openssh.authorizedKeys.keys = self.keys-admin;
    services.getty.autologinUser = "root";

    nix.settings.experimental-features = ["flakes" "nix-command"];

    environment.systemPackages = with pkgs; [
      btrfs-progs
      git
      gptfdisk
      parted
      rsync
      smartmontools
      tmux
      vim
    ];

    nixpkgs.hostPlatform = "x86_64-linux";
    system.nixos.label = "homelab-rescue";
    system.stateVersion = "26.05";
  };
}
