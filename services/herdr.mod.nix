{self, ...}: {
  flake.serviceModules.herdr = {
    config,
    lib,
    ...
  }: let
    cfg = config.herdr;
  in {
    imports = [self.serviceModules.base];

    options.herdr.package = lib.mkOption {
      type = lib.types.package;
      description = "Herdr package to run.";
    };

    config = {
      exec = {
        argv = [(lib.getExe cfg.package) "server"];
        allowMemory = true;
      };

      network = {
        reach = [
          "0.0.0.0/0"
          "::/0"
        ];
        bind = [{v4.tcp = 0;}];
      };

      limits.syscalls = [
        "@system-service"
        "@pkey"
      ];
    };
  };
}
