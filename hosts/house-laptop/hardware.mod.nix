_: {
  flake.nixosModules.house-laptop-hardware = {
    config,
    lib,
    modulesPath,
    ...
  }: {
    hardware = {
      facter.reportPath = ./report.json;
      cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };

    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot = {
      initrd = {
        availableKernelModules = ["xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod"];
        kernelModules = [];
      };
      kernelModules = ["kvm-intel"];
      extraModulePackages = [];
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
