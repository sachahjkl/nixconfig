{ ... }:

{
  flake.nixosModules.tailscale = { lib, pkgs, ... }: {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "client";
    };

    networking.firewall.trustedInterfaces = [ "tailscale0" ];

    environment.systemPackages = [ pkgs.trayscale ];

    systemd.user.services.trayscale = {
      description = "Tailscale tray icon";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = lib.getExe pkgs.trayscale;
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    preferences.preservation.system.directories = [ "/var/lib/tailscale" ];
  };
}
