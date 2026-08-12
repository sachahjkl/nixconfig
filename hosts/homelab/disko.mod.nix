_: {
  flake.diskoConfigurations.homelab = {
    disko.devices = {
      disk.main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-INTEL_SSDPEKNW512G8H_PHNH9274019T512A";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              label = "ESP";
              name = "ESP";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };

            swap = {
              label = "swap";
              name = "swap";
              size = "8G";
              content.type = "swap";
            };

            root = {
              label = "nixos-root";
              name = "nixos-root";
              size = "96G";
              content = {
                type = "btrfs";
                extraArgs = ["-f"];
                subvolumes = {
                  "/persist" = {
                    mountpoint = "/persist";
                    mountOptions = ["subvol=persist" "compress=zstd" "noatime"];
                  };

                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["subvol=nix" "compress=zstd" "noatime"];
                  };
                };
              };
            };

            data = {
              label = "data";
              name = "data";
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f" "-L" "data"];
                subvolumes = {
                  "@data" = {
                    mountpoint = "/data";
                    mountOptions = ["compress=zstd" "noatime" "space_cache=v2"];
                  };

                  "@data-agents" = {
                    mountpoint = "/data/Agents";
                    mountOptions = ["compress=zstd" "noatime"];
                  };

                  "@data-backups" = {
                    mountpoint = "/data/Backups";
                    mountOptions = ["compress=zstd" "noatime"];
                  };

                  "@data-docker-appdata" = {
                    mountpoint = "/data/Docker/appdata";
                    mountOptions = ["compress=zstd" "noatime"];
                  };

                  "@data-docker-backup" = {
                    mountpoint = "/data/Docker/backup";
                    mountOptions = ["compress=zstd" "noatime"];
                  };

                  "@data-docker-data" = {
                    mountpoint = "/data/Docker/data";
                    mountOptions = ["compress=zstd" "noatime"];
                  };

                  "@data-docker-storage" = {
                    mountpoint = "/data/Docker/storage";
                    mountOptions = ["compress=zstd:1" "noatime"];
                  };

                  "@data-downloads" = {
                    mountpoint = "/data/Downloads";
                    mountOptions = ["compress=zstd:3" "noatime"];
                  };

                  "@data-home" = {
                    mountpoint = "/data/Home";
                    mountOptions = ["compress=zstd" "noatime"];
                  };

                  "@data-github-runner" = {
                    mountpoint = "/var/lib/github-runner";
                    mountOptions = ["compress=zstd:1" "noatime"];
                  };

                  "@data-media" = {
                    mountpoint = "/data/Media";
                    mountOptions = ["compress=zstd:1" "noatime"];
                  };

                  "@data-secrets" = {
                    mountpoint = "/data/Secrets";
                    mountOptions = ["compress=zstd" "noatime"];
                  };

                  "@data-vms" = {
                    mountpoint = "/data/VMs";
                    mountOptions = ["compress=zstd:1" "noatime"];
                  };
                };
              };
            };
          };
        };
      };

      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = ["size=25%" "mode=755"];
      };
    };
  };
}
