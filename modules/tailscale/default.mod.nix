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
    hasPreservationDirs = lib.hasAttrByPath ["persist" "system" "directories"] options;
  in {
    options.network.tailscale = {
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
            assertion = !(config.network.tailscale.authKeyFile != null && config.network.tailscale.sopsSecretName != null);
            message = "Use either network.tailscale.authKeyFile or network.tailscale.sopsSecretName, not both.";
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
        persist.system.directories = singleton "/var/lib/tailscale";
      })

      (mkIf (config.network.tailscale.sopsSecretName != null) {
        sharedSops.enable = true;

        sops.secrets.${config.network.tailscale.sopsSecretName} = {
          owner = "root";
          group = "root";
          mode = "0400";
        };

        services.tailscale.authKeyFile = config.sops.secrets.${config.network.tailscale.sopsSecretName}.path;
      })

      (mkIf (config.network.tailscale.authKeyFile != null) {
        services.tailscale.authKeyFile = config.network.tailscale.authKeyFile;
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
