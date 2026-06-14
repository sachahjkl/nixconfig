{self, ...}: {
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
        default = self.packages.${pkgs.stdenv.hostPlatform.system}."sacha.house";
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
        default = "/data/Services/sacha.house";
      };

      user = mkOption {
        type = types.str;
        default = config.userName;
      };

      group = mkOption {
        type = types.str;
        default = config.users.users.${config.userName}.group or "users";
      };
    };

    config = mkIf cfg.enable {
      systemd.tmpfiles.rules = [
        "d ${cfg.workingDirectory} 0755 ${cfg.user} ${cfg.group} -"
      ];

      systemd.services."sacha.house" = {
        description = "Sacha House Web Server";
        after = ["network-online.target"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
        unitConfig = {
          ConditionPathExists = "${cfg.workingDirectory}/config.json";
        };
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

  perSystem = {pkgs, ...}: let
    cfg = {
      releaseVersion = "2026.05.08+d84007a9";
      releaseBinaryUrl = "https://gitlab.com/sachahjkl/sacha.house/-/jobs/artifacts/master/raw/sacha.house-linux-amd64?job=build:linux:release";
      releaseBinaryHash = "sha256-846ACs/s3935pRfjNG5Sp0q/cMZWCGDV2s7mynS4L+E=";
    };
    # The upstream binary links against libcmark.so.0.30.2, but nixpkgs ships
    # a newer soname. Provide a compatibility symlink so autoPatchelfHook can
    # resolve the library at runtime.
    cmark-compat = pkgs.runCommand "cmark-0.30.2-compat" {} ''
      mkdir -p "$out/lib"
      ln -s "${pkgs.cmark}/lib/libcmark.so.0.31.1" "$out/lib/libcmark.so.0.30.2"
    '';
  in {
    packages."sacha.house" = pkgs.stdenv.mkDerivation {
      pname = "sacha-house";
      version = cfg.releaseVersion;
      src = pkgs.fetchurl {
        url = cfg.releaseBinaryUrl;
        hash = cfg.releaseBinaryHash;
        name = "sacha.house-linux-amd64";
      };
      dontUnpack = true;
      nativeBuildInputs = [pkgs.autoPatchelfHook];
      buildInputs = [pkgs.openssl_3 cmark-compat];
      installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin"
        cp "$src" "$out/bin/sacha.house"
        chmod +x "$out/bin/sacha.house"
        runHook postInstall
      '';

      meta.mainProgram = "sacha.house";
    };
  };
}
