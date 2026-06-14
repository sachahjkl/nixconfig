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
        default = "/var/lib/sops-nix/key.txt";
        description = "Age key file used by sops-nix on the homelab host.";
      };
    };

    config = mkIf cfg.enable {
      preferences.sops = {
        enable = true;
        inherit (cfg) defaultSopsFile ageKeyFile;
        passwordHashSecretName = "shared/password-hash";
        passwordHashFromSharedFile = true;
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
      };

      homelab.backup.resticEnvironmentFile = mkDefault config.sops.secrets."restic/environment".path;
      homelab.backup.resticPasswordFile = mkDefault config.sops.secrets."restic/password".path;
    };
  };
}
