{
  flake.diskoConfigurations.house-desktop = {
    disko.devices = {
      disk.main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-PNY_CS2230_1TB_SSD_PNF01230035710900504";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              name = "ESP";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            swap = {
              size = "34G";
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };

            root = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings.allowDiscards = true;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "subvol=persist" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "subvol=nix" "noatime" ];
                    };
                  };
                };
              };
            };
          };
        };
      };

      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = [ "size=25%" "mode=755" ];
      };
    };
  };
}
