{self, ...}: {
  flake.nixosModules.windowsVm = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkOption types;
    cfg = config.services.windowsVm;
    secretName = "windows-vm/environment";

    # dockur/windows copies this folder to C:\OEM and runs install.bat at the first logon.
    # Plain files, not symlinks: the container cannot follow links into the Nix store.
    oem = pkgs.runCommand "windows-vm-oem" {} ''
      mkdir $out
      cp ${./windows-vm/setup.ps1} $out/setup.ps1
      printf '%s\r\n' '@echo off' 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\OEM\setup.ps1' > $out/install.bat
      printf '%s\r\n' ${lib.escapeShellArgs cfg.authorizedKeys} > $out/authorized_keys
    '';
  in {
    imports = [self.nixosModules.sops];

    options.services.windowsVm = {
      enable = mkEnableOption "the Windows 11 build and test VM (dockur/windows)";

      dataDir = mkOption {
        type = types.str;
        description = "Directory with the VM's disk image, firmware variables and installation media.";
      };

      address = mkOption {
        type = types.str;
        description = "Host address that the VM's SSH and RDP ports bind to. Use the Tailscale address to keep them off the internet.";
      };

      sshPort = mkOption {
        type = types.port;
        default = 2222;
        description = "Host port forwarded to the VM's SSH server.";
      };

      rdpPort = mkOption {
        type = types.port;
        default = 3389;
        description = "Host port forwarded to the VM's Remote Desktop.";
      };

      webPort = mkOption {
        type = types.port;
        default = 8006;
        description = "Port of the VM's console in a browser, on 127.0.0.1 only (reach it with ssh -L).";
      };

      cpuCores = mkOption {
        type = types.ints.positive;
        default = 4;
        description = "Virtual CPU cores.";
      };

      ramSize = mkOption {
        type = types.str;
        default = "6G";
        description = "Maximum memory of the VM. The balloon gives memory back to the host under pressure.";
      };

      minRamSize = mkOption {
        type = types.str;
        default = "2G";
        description = "Memory that the balloon never takes from the VM.";
      };

      diskSize = mkOption {
        type = types.str;
        default = "64G";
        description = "Size of the VM's system disk.";
      };

      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = self.keys-admin;
        description = "SSH public keys allowed to log in as the VM's user.";
      };
    };

    config = mkIf cfg.enable {
      # The file holds PASSWORD=<the Windows account's password>, used once by the unattended installation.
      sops.secrets.${secretName} = {
        owner = "root";
        group = "root";
        mode = "0400";
      };

      virtualisation.oci-containers = {
        backend = "docker";
        containers.windows-vm = {
          image = "docker.io/dockurr/windows:6.06";
          # Started on demand (systemctl start docker-windows-vm) and stopped after use: it takes 6 GB of 14.
          autoStart = false;
          environment = {
            # Windows 11 Enterprise evaluation: no key, 90 days, then a new installation.
            VERSION = "11e";
            USERNAME = "dev";
            CPU_CORES = toString cfg.cpuCores;
            RAM_SIZE = cfg.ramSize;
            DISK_SIZE = cfg.diskSize;
            BALLOONING = "Y";
            BALLOONING_MIN_MEM = cfg.minRamSize;
            # dockur's shared folder and its desktop shortcuts: not used, files move over ssh.
            SAMBA = "N";
          };
          environmentFiles = [config.sops.secrets.${secretName}.path];
          volumes = [
            "${cfg.dataDir}:/storage"
            "${oem}:/oem:ro"
          ];
          ports = [
            "${cfg.address}:${toString cfg.sshPort}:22/tcp"
            "${cfg.address}:${toString cfg.rdpPort}:3389/tcp"
            "${cfg.address}:${toString cfg.rdpPort}:3389/udp"
            "127.0.0.1:${toString cfg.webPort}:8006/tcp"
          ];
          extraOptions = [
            "--device=/dev/kvm"
            "--device=/dev/net/tun"
            "--cap-add=NET_ADMIN"
            # The host's services win the CPU when both want it (the default weight is 1024).
            "--cpu-shares=256"
            # Windows gets an ACPI shutdown and up to 105 s to stop.
            "--stop-timeout=120"
          ];
        };
      };

      systemd = {
        # A raw disk image on Btrfs: no copy-on-write, or every guest write fragments the file.
        tmpfiles.rules = [
          "d ${cfg.dataDir} 0750 root root -"
          "h ${cfg.dataDir} - - - - +C"
        ];

        services.docker-windows-vm = {
          # The ports bind the Tailscale address, which only exists once tailscaled is up.
          wants = ["network-online.target"];
          after = ["network-online.target" "tailscaled.service"];
          unitConfig.RequiresMountsFor = [cfg.dataDir];
          # oci-containers gives 120 s, as much as the container's own stop timeout.
          serviceConfig.TimeoutStopSec = lib.mkForce 150;
        };
      };
    };
  };
}
