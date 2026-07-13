{inputs, ...}: {
  flake.nixosModules.sachaHouseService = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
    cfg = config.homelab.services.sachaHouse;
  in {
    imports = [inputs.sacha-house.nixosModules.default];

    options.homelab.services.sachaHouse = {
      enable = mkEnableOption "sacha.house web service";

      package = mkOption {
        type = types.package;
        default = inputs.sacha-house.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
      services.sacha-house = {
        enable = true;
        inherit (cfg) package port dataDir openFirewall;
        configFile = "${cfg.dataDir}/config.json";
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0755 sacha-house sacha-house -"
      ];

      homelab.proxy.hosts."sacha.house" = {
        upstreamHost = mkDefault "127.0.0.1";
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
