_: {
  flake.diskoConfigurations.kids-desktop = {
    config,
    lib,
    ...
  }: {
    options.kidsDesktop.diskDevice = lib.mkOption {
      type = lib.types.str;
      default = "/dev/disk/by-id/REPLACE_WITH_KIDS_DESKTOP_DISK";
      description = "Stable device path for the kids desktop system disk.";
    };

    config.disko.devices.disk.main = {
      type = "disk";
      device = config.kidsDesktop.diskDevice;
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
              mountOptions = ["umask=0077"];
            };
          };

          swap = {
            size = "16G";
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };

          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
