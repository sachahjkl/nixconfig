{self, ...}: {
  flake.nixosModules.serverTailscale = {
    config,
    lib,
    ...
  }: {
    imports = [self.nixosModules.tailscale];

    network.tailscale.sopsSecretName = lib.mkDefault "tailscale/server-authkey";

    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "client";
    };

    networking.firewall.trustedInterfaces = [config.services.tailscale.interfaceName];

    systemd.services.tailscaled.serviceConfig.Environment = lib.mkIf config.networking.nftables.enable [
      "TS_DEBUG_FIREWALL_MODE=nftables"
    ];
  };
}
