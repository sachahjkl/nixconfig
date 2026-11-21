{self, ...}: {
  flake.nixosModules.serverTailscale = {lib, ...}: {
    imports = [self.nixosModules.tailscale];

    network.tailscale.sopsSecretName = lib.mkDefault "tailscale/server-authkey";

    services.tailscale = {
      openFirewall = true;
      useRoutingFeatures = "client";
    };
  };
}
