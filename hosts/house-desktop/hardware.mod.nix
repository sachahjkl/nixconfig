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
        package = config.boot.kernelPackages.nvidiaPackages.stable;
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
      # Use the LTS kernel. The NixOS stable NVIDIA driver supports it, and the
      # driver does not need a manual pin after each new kernel release.
      kernelPackages = pkgs.linuxPackages;
      initrd = {
        availableKernelModules = ["nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"];
        kernelModules = ["nvidia" "nvidia_modeset" "nvidia_drm"];
      };
      kernelModules = ["kvm-amd"];
      extraModulePackages = [];
    };

    # The MT7927's Bluetooth half answers on USB only once the Wi-Fi driver has started the chip.
    # Enumerated before that, early in the boot, it stops answering until the power is cut. When
    # it is missing once the Wi-Fi is up, its USB controller (also the keyboard's and the mouse's,
    # for a few seconds) is enumerated again. Only during the boot: never under a session.
    systemd.services.mt7927-bluetooth-enumerate = {
      description = "Enumerate the MT7927 Bluetooth again once its Wi-Fi has started the chip";
      wantedBy = ["multi-user.target"];
      after = ["systemd-modules-load.service" "network-pre.target"];
      before = ["bluetooth.service" "display-manager.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        controller=0000:02:00.0
        present() {
          for device in /sys/bus/usb/devices/*; do
            [ "$(cat "$device/idVendor" 2>/dev/null)" = 0489 ] && return 0
          done
          return 1
        }
        uptime=$(cut -d. -f1 /proc/uptime)
        if [ "$uptime" -gt 180 ]; then
          echo "not during the boot (up for $uptime s): nothing done"
          exit 0
        fi
        # The Wi-Fi driver has the chip once its interface exists.
        for _ in $(seq 1 40); do
          ls /sys/bus/pci/drivers/mt7925e/ 2>/dev/null | grep -q '^0000:' && break
          sleep 0.5
        done
        if present; then
          echo "Bluetooth present"
          exit 0
        fi
        echo "Bluetooth missing: enumerating $controller again"
        echo "$controller" > /sys/bus/pci/drivers/xhci_hcd/unbind
        sleep 3
        echo "$controller" > /sys/bus/pci/drivers/xhci_hcd/bind
        for _ in $(seq 1 30); do
          present && { echo "Bluetooth present"; exit 0; }
          sleep 1
        done
        echo "Bluetooth still missing: cut the power (PSU switch) for 10 s to free the chip"
      '';
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    # ryzen_smu: the SMU's power table, readable by every user, where
    # Inspecteur finds each core's temperature (k10temp gives only the
    # package's and the CCD's). Only root can send commands to the SMU.
    hardware.cpu.amd.ryzen-smu.enable = true;
  };
}
