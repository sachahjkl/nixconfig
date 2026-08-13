_: {
  flake.nixosModules.wslContainers = {
    config,
    pkgs,
    ...
  }: {
    config = {
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };

      environment.systemPackages = with pkgs; [
        podman-compose
      ];

      users.users.${config.userName}.linger = true;

      systemd.user.services.podman-prune = {
        description = "Prune rootless Podman resources";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.podman}/bin/podman system prune --force --all --volumes";
        };
      };

      systemd.user.timers.podman-prune = {
        description = "Weekly rootless Podman prune";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
          RandomizedDelaySec = "30m";
        };
      };
    };
  };
}
