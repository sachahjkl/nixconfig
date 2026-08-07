{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.sachaHouseService = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
    cfg = config.homelab.services.sachaHouse;
  in {
    options.homelab.services.sachaHouse = {
      enable = mkEnableOption "sacha.house web service";

      package = mkOption {
        type = types.package;
        default = inputs.sacha-house.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Host address the sacha.house service binds.";
      };

      port = mkOption {
        type = types.port;
        default = 6969;
        description = "Port the sacha.house web server listens on.";
      };

      dataDir = mkOption {
        type = types.path;
        default = "/data/Services/sacha.house";
        description = "Working directory for runtime data; config is read from dataDir/config.json.";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = "Open the configured port in the firewall.";
      };
    };

    config = mkIf cfg.enable {
      users.users.sacha-house = {
        isSystemUser = true;
        group = "sacha-house";
        home = cfg.dataDir;
        createHome = true;
      };
      users.groups.sacha-house = {};

      system.services.sacha-house = {
        imports = [self.serviceModules.sachaHouse];

        sachaHouse = {
          inherit (cfg) package host port dataDir;
          secretspecPackage = inputs.sacha-house.packages.${pkgs.stdenv.hostPlatform.system}.secretspec;
          sopsPackage = pkgs.sops;
          configFile = "${cfg.dataDir}/config.json";
          ageKeyFile = config.homelab.sops.ageKeyFile;
        };

        systemd.service = {
          description = "sacha.house web service";
          after = ["network-online.target"];
          wants = ["network-online.target"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            User = "sacha-house";
            Group = "sacha-house";
            DynamicUser = lib.mkForce false;
            PrivateUsers = lib.mkForce false;
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0755 sacha-house sacha-house -"
      ];

      homelab.proxy.hosts."sacha.house" = {
        upstreamHost = mkDefault cfg.host;
        upstreamPort = mkDefault cfg.port;
        http2 = mkDefault true;
        dns = {
          type = mkDefault "A";
          value = mkDefault "82.66.185.90";
          proxied = mkDefault false;
        };
      };
    };
  };
}
