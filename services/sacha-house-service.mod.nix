_: {
  flake.nixosModules.sachaHouseService = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkDefault mkEnableOption mkIf mkOption types;
    cfg = config.homelab.services.sachaHouse;
    package =
      pkgs.runCommand "sacha-house-${cfg.releaseVersion}"
      {
        src = pkgs.fetchurl {
          url = cfg.releaseBinaryUrl;
          hash = cfg.releaseBinaryHash;
          name = "sacha.house-linux-amd64";
        };
      } ''
        mkdir -p "$out/bin"
        cp "$src" "$out/bin/sacha.house"
        chmod +x "$out/bin/sacha.house"
      '';
  in {
    options.homelab.services.sachaHouse = {
      enable = mkEnableOption "sacha.house web service";

      package = mkOption {
        type = types.package;
        default = package;
      };

      releaseVersion = mkOption {
        type = types.str;
        default = "2026.05.08+d84007a9";
      };

      releasePageUrl = mkOption {
        type = types.str;
        default = "https://gitlab.com/sachahjkl/sacha.house/-/releases/${cfg.releaseVersion}";
      };

      releaseBinaryUrl = mkOption {
        type = types.str;
        default = "https://gitlab.com/sachahjkl/sacha.house/-/jobs/artifacts/master/raw/sacha.house-linux-amd64?job=build:linux:release";
      };

      releaseBinaryHash = mkOption {
        type = types.str;
        default = "sha256-846ACs/s3935pRfjNG5Sp0q/cMZWCGDV2s7mynS4L+E=";
      };

      workingDirectory = mkOption {
        type = types.str;
        default = "/opt/sacha.house";
      };

      user = mkOption {
        type = types.str;
        default = config.userName;
      };

      group = mkOption {
        type = types.str;
        default = config.userName;
      };
    };

    config = mkIf cfg.enable {
      systemd.services."sacha.house" = {
        description = "Sacha House Web Server";
        after = ["network-online.target"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
        startLimitIntervalSec = 0;
        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.workingDirectory;
          ExecStart = "${cfg.package}/bin/sacha.house";
          Restart = "on-failure";
          RestartSec = 10;
          StandardOutput = "journal";
          StandardError = "journal";
          KillSignal = "SIGINT";
        };
      };

      homelab.proxy.hosts."sacha.house" = {
        upstreamHost = mkDefault "127.0.0.1";
        upstreamPort = mkDefault 6969;
        http2 = mkDefault false;
      };
    };
  };
}
