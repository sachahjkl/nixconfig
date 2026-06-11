_: {
  flake.nixosModules.tailscale = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.lists) singleton;
    inherit (lib.meta) getExe;
    inherit (lib.modules) mkAfter mkIf;
  in {
    options.preferences.tailscale = {
      authKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to a file containing the Tailscale auth key (used for pre-auth on servers).";
      };
    };

    config = lib.mkMerge [
      {
        services.tailscale = {
          enable = true;
          interfaceName = "ts0";
          useRoutingFeatures = "both";
          extraUpFlags = mkAfter [
            "--login-server=https://controlplane.tailscale.com"
          ];
        };

        networking.firewall.trustedInterfaces = singleton config.services.tailscale.interfaceName;

        preferences.preservation.system.directories = singleton "/var/lib/tailscale";
      }

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
