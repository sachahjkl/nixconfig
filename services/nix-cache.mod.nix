{self, ...}: {
  flake.nixosModules.nixCache = {
    config,
    pkgs,
    ...
  }: let
    secretName = "nix-cache/signing-key";
  in {
    imports = [self.nixosModules.sops];

    sops.secrets.${secretName} = {
      sopsFile = builtins.path {
        path = self + /secrets/homelab.yaml;
        name = "homelab-secrets.yaml";
      };
      owner = "root";
      group = "root";
      mode = "0400";
    };

    services.nix-serve = {
      enable = true;
      bindAddress = "127.0.0.1";
      package = pkgs.nix-serve-ng;
      port = 5000;
      secretKeyFile = config.sops.secrets.${secretName}.path;
    };
  };
}
