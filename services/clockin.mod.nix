{self, ...}: {
  flake.serviceModules.clockin = {
    config,
    lib,
    options,
    ...
  }: let
    cfg = config.clockin;
  in {
    imports = [self.serviceModules.base];

    options.clockin = {
      package = lib.mkOption {
        type = lib.types.package;
        description = "Clock-in package to run.";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3000;
      };

      databaseDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/clockin";
      };

      allowedHosts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["clockin.sacha.house" "127.0.0.1" "localhost"];
      };
    };

    config = {
      exec = {
        argv = [(lib.getExe' cfg.package "clockin")];
        allowMemory = true;
      };

      network = {
        reach = ["127.0.0.1/32"];
        bind = [{v4.tcp = cfg.port;}];
      };

      files.${cfg.databaseDir} = ["read" "write"];

      limits.syscalls = ["@system-service" "@pkey"];

      ${
        if options ? systemd
        then "systemd"
        else null
      }.service = {
        description = "Clock-in pointage service";
        after = ["network.target"];
        wantedBy = ["multi-user.target"];
        environment = {
          HOST = cfg.host;
          PORT = toString cfg.port;
          DATABASE_URL = "${cfg.databaseDir}/clockin.sqlite";
          NG_ALLOWED_HOSTS = lib.concatStringsSep "," cfg.allowedHosts;
        };
        serviceConfig = {
          User = "clockin";
          Group = "clockin";
          DynamicUser = lib.mkForce false;
          PrivateUsers = lib.mkForce false;
          WorkingDirectory = cfg.databaseDir;
        };
      };
    };
  };
}
