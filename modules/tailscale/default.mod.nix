_: {
  flake.nixosModules.tailscale = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    inherit (lib.lists) singleton;
    inherit (lib.meta) getExe;
    inherit (lib.modules) mkAfter mkIf;
    hasPreservationDirs = lib.hasAttrByPath ["preferences" "preservation" "system" "directories"] options;
  in {
    options.preferences.tailscale = {
      authKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to a file containing the Tailscale auth key (used for pre-auth on servers).";
      };

      sopsSecretName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Name of the SOPS secret providing the Tailscale auth key for this host.";
      };
    };

    config = lib.mkMerge [
      {
        assertions = [
          {
            assertion = !(config.preferences.tailscale.authKeyFile != null && config.preferences.tailscale.sopsSecretName != null);
            message = "Use either preferences.tailscale.authKeyFile or preferences.tailscale.sopsSecretName, not both.";
          }
        ];
      }

      {
        services.tailscale = {
          enable = true;
          interfaceName = "ts0";
          useRoutingFeatures = lib.mkDefault "both";
          extraSetFlags = [
            "--ssh"
          ];
          extraUpFlags = mkAfter [
            "--login-server=https://controlplane.tailscale.com"
          ];
        };

        networking.firewall.trustedInterfaces = singleton config.services.tailscale.interfaceName;
      }

      (lib.optionalAttrs hasPreservationDirs {
        preferences.preservation.system.directories = singleton "/var/lib/tailscale";
      })

      (mkIf (config.preferences.tailscale.sopsSecretName != null) {
        preferences.sops.enable = true;

        sops.secrets.${config.preferences.tailscale.sopsSecretName} = {
          owner = "root";
          group = "root";
          mode = "0400";
        };

        services.tailscale.authKeyFile = config.sops.secrets.${config.preferences.tailscale.sopsSecretName}.path;
      })

      (mkIf (config.preferences.tailscale.authKeyFile != null) {
        services.tailscale.authKeyFile = config.preferences.tailscale.authKeyFile;
      })

      (mkIf config.networking.nftables.enable {
        systemd.services.tailscaled.serviceConfig.Environment = singleton "TS_DEBUG_FIREWALL_MODE=nftables";
      })

      {
        systemd.user.services.tailscale-systray = {
          description = "Tailscale tray icon";
          wantedBy = ["graphical-session.target"];
          partOf = ["graphical-session.target"];
          after = ["graphical-session.target"];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${getExe pkgs.tailscale} systray";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      }
    ];
  };
}
