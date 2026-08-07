{
  inputs,
  self,
  ...
}: {
  flake.serviceModules.sachaHouse = {
    config,
    lib,
    ...
  }: let
    cfg = config.sachaHouse;
  in {
    imports = [self.serviceModules.base];

    options.sachaHouse = {
      package = lib.mkOption {
        type = lib.types.package;
        description = "sacha.house package to run.";
      };

      secretspecPackage = lib.mkOption {
        type = lib.types.package;
        description = "SecretSpec package used to resolve runtime secrets.";
      };

      sopsPackage = lib.mkOption {
        type = lib.types.package;
        description = "SOPS package used by the SecretSpec provider.";
      };

      manifest = lib.mkOption {
        type = lib.types.path;
        default = inputs.sacha-house + /secretspec.toml;
        description = "SecretSpec manifest for the service.";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host address the service binds.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 6969;
        description = "Port the service binds.";
      };

      dataDir = lib.mkOption {
        type = lib.types.str;
        description = "Writable directory for runtime data.";
      };

      configFile = lib.mkOption {
        type = lib.types.str;
        description = "JSON configuration file read by the application.";
      };

      ageKeyFile = lib.mkOption {
        type = lib.types.str;
        description = "Age identity source provided as a protected credential.";
      };
    };

    config = {
      exec = {
        argv = [
          (lib.getExe cfg.secretspecPackage)
          "--file"
          cfg.manifest
          "--reason"
          "Start sacha.house service"
          "run"
          "--profile"
          "production"
          "--scope"
          "runtime"
          "--"
          (lib.getExe' cfg.package "sacha.house")
        ];
        path = [cfg.sopsPackage];
        environment = {
          CONFIG_PATH = cfg.configFile;
          HOST = cfg.host;
          PORT = toString cfg.port;
        };
        workingDirectory = cfg.dataDir;
        credentials.sops-age-key = {
          source = cfg.ageKeyFile;
          environment = "SOPS_AGE_KEY_FILE";
        };
      };

      network = {
        reach = [
          "0.0.0.0/0"
          "::/0"
        ];
        bind = [{v4.tcp = cfg.port;}];
      };

      files.${cfg.dataDir} = ["read" "write"];
    };
  };
}
