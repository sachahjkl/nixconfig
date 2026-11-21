{
  inputs,
  self,
  lib,
  ...
}: let
  commonModule = {...}: {
    imports = [
      inputs.nixos-wsl.nixosModules.default
      self.nixosModules.common
      self.nixosModules.wsl-hardware
      self.nixosModules.wslContainers
    ];

    wsl = {
      enable = true;
      defaultUser = "nixos";
      interop.register = true;
    };

    systemd.tmpfiles.rules = [
      "z /etc/ssh/ssh_host_ed25519_key 0600 root root -"
    ];

    userName = "nixos";
    fullName = "NixOS";

    ai = {
      enable = true;
      hex.enable = false;
      herdr.enable = true;
    };

    sharedSops = {
      enable = true;
      passwordHashSecretName = "shared/password-hash";
    };

    persist.enable = false;

    system.stateVersion = "26.05";
  };
in {
  imports = [
    (lib.systems.nixosSystem "ogf-wsl" {
      module = {
        imports = [commonModule];

        # Work machine: keep the personal Cloudflare token off it.
        cloudflareCli.enable = false;

        security.pki.certificateFiles = [
          ./certs/zscaler-root-ca.pem
          ./certs/ca-ogfprod-root.pem
        ];
      };
    })

    (lib.systems.nixosSystem "sacha-pc-wsl" {
      module = {
        imports = [
          commonModule
          self.nixosModules.tailscale
        ];

        network.tailscale.sopsSecretName = "tailscale/user-authkey";
        services.tailscale.extraSetFlags = lib.mkAfter ["--hostname=sacha-pc-wsl"];
      };
    })
  ];
}
