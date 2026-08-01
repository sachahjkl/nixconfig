{inputs, ...}: {
  flake.nixosModules.house-desktop-hardware = {
    config,
    lib,
    modulesPath,
    pkgs,
    ...
  }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    hardware = {
      graphics.enable = true;

      nvidia = {
        modesetting.enable = true;
        nvidiaSettings = true;
        open = true;
        nvidiaPersistenced = true;
        powerManagement.enable = true;
      };

      mediatek-mt7927 = {
        enable = true;
        enableWifi = true;
        enableBluetooth = true;
        disableAspm = true;
      };

      firmware = [
        (pkgs.runCommand "mediatek-mt7927-bluetooth-firmware" {} ''
          install -Dm644 \
            ${inputs.mt7927.packages.${pkgs.stdenv.hostPlatform.system}.firmware}/lib/firmware/mediatek/mt6639/BT_RAM_CODE_MT6639_2_1_hdr.bin \
            $out/lib/firmware/mediatek/mt7927/BT_RAM_CODE_MT6639_2_1_hdr.bin
        '')
      ];

      facter.reportPath = ./report.json;
    };

    boot = {
      initrd = {
        availableKernelModules = ["nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"];
        kernelModules = [];
      };
      kernelModules = ["kvm-amd"];
      extraModulePackages = [];
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
