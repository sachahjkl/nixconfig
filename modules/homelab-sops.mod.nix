{self, ...}: {
  flake.nixosModules.homelabSops = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkOption mkDefault types;
    cfg = config.homelab.sops;
  in {
    options.homelab.sops = {
      enable = mkEnableOption "sops-nix integration for the homelab host";

      defaultSopsFile = mkOption {
        type = types.nullOr types.path;
        default = self + /secrets/homelab.yaml;
        description = "Encrypted SOPS file used by the homelab host.";
      };

      ageKeyFile = mkOption {
        type = types.str;
        default = "/persist/var/lib/sops-nix/key.txt";
        description = "Age key file used by sops-nix on the homelab host.";
      };
    };

    config = mkIf cfg.enable {
      sharedSops = {
        enable = true;
        inherit (cfg) defaultSopsFile ageKeyFile;
        passwordHashSecretName = "shared/password-hash";
        passwordHashSopsFile = self + /secrets/shared.yaml;
      };

      sops.secrets = {
        "restic/environment" = {
          owner = "root";
          group = "root";
          mode = "0400";
        };

        "restic/password" = {
          owner = "root";
          group = "root";
          mode = "0400";
        };

        "observability/grafana-environment" = {
          owner = "root";
          group = "root";
          mode = "0400";
          restartUnits = ["docker-grafana.service"];
        };

        "observability/otlp-htpasswd" = {
          owner = "root";
          group = "nginx";
          mode = "0440";
          restartUnits = ["nginx.service"];
        };
      };

      homelab.backup = {
        resticEnvironmentFile = mkDefault config.sops.secrets."restic/environment".path;
        resticPasswordFile = mkDefault config.sops.secrets."restic/password".path;
      };
    };
  };
}
