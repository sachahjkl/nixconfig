{
  inputs,
  self,
  lib,
  ...
}: let
  commonModule = {lib, ...}: {
    imports = [
      inputs.nixos-wsl.nixosModules.default
      self.nixosModules.wsl-hardware
      self.nixosModules.baseUser
      self.nixosModules.external-preservation
      self.nixosModules.ai
      self.nixosModules.editor
      self.nixosModules.fish
      self.nixosModules.home-manager
      self.nixosModules.hjem
      self.nixosModules.mosh
      self.nixosModules.moshiHook
      self.nixosModules.neovim
      self.nixosModules.nix
      self.nixosModules.nixCommon
      self.nixosModules.opencode
      self.nixosModules.packages
      self.nixosModules.preservation
      self.nixosModules.sharedSops
      self.nixosModules.ssh
      self.nixosModules.user-home
      self.nixosModules.wslContainers
      self.nixosModules.xdgStubs
    ];

    wsl = {
      enable = true;
      defaultUser = "nixos";
      interop.register = true;
    };

    userName = "nixos";
    fullName = "NixOS";
    homeDirectory = "/home/nixos";
    extraUserGroups = ["docker"];

    ai = {
      enable = true;
      handy.enable = false;
      herdr.enable = true;
    };

    moshi.enable = true;

    git.signingKey = "~/.ssh/far-from-home.pub";
    ssh.identityKey = "~/.ssh/far-from-home";

    sharedSops = {
      enable = true;
      passwordHashSecretName = "shared/password-hash";
    };

    persist.enable = lib.mkForce false;

    system.stateVersion = "26.05";
  };
in {
  imports = [
    (lib.systems.nixosSystem "ogf-wsl" {
      module = {
        imports = [commonModule];

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
