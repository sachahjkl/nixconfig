{self, ...}: {
  flake.serviceModules.lanblaster = {
    config,
    lib,
    options,
    ...
  }: let
    cfg = config.lanblaster;
  in {
    imports = [self.serviceModules.base];

    options.lanblaster = {
      package = lib.mkOption {
        type = lib.types.package;
        description = "Lanblaster package to run.";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8013;
      };
    };

    config = {
      exec = {
        argv = [(lib.getExe' cfg.package "lanblaster-server")];
        allowMemory = true;
      };

      network = {
        reach = ["127.0.0.1/32"];
        bind = [{v4.tcp = cfg.port;}];
      };

      limits = {
        storage = true;
        syscalls = ["@system-service" "@pkey"];
      };

      ${
        if options ? systemd
        then "systemd"
        else null
      }.service = {
        description = "Lanblaster game server";
        after = ["network-online.target"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
        environment = {
          HOST = cfg.host;
          PORT = toString cfg.port;
        };
      };
    };
  };
}
