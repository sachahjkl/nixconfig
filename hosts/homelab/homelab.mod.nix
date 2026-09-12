{
  self,
  lib,
  ...
}:
lib.systems.nixosSystem "homelab" {
  module = {config, ...}: {
    imports = [
      self.nixosModules.disko
      self.diskoConfigurations.homelab
      self.nixosModules.deployUser
      self.nixosModules.homelab
      self.nixosModules.homelab-hardware
      self.nixosModules.homelabProxyHosts
      self.nixosModules.codexProxyService
      self.nixosModules.nixCache
      self.nixosModules.ai
    ];

    userName = "sacha";
    fullName = "Sacha";
    extraUserGroups = ["docker"];
    users.mutableUsers = lib.mkForce false;
    homeDirectory = "/data/Home/sacha";

    ai = {
      enable = true;
      handy.enable = false;
      herdr.enable = true;
    };

    homelab = {
      lanInterface = "eno1";
      dataRoot = "/data";

      sops = {
        enable = true;
      };

      services = {
        observability = {
          enable = true;
          grafanaDomain = "grafana.sacha.house";
          otlpDomain = "otlp.sacha.house";
        };

        githubRunner = {
          enable = true;
          repositories = {
            nixconfig = "https://github.com/sachahjkl/nixconfig";
          };
        };
        hermesDashboard.enable = false;
        codexProxy.enable = true;
        filebrowser.enable = true;
        nomad = {
          enable = true;
          server = true;
          client = true;
          ingress = true;
          nodeClass = "general";
          address = "100.106.51.80";
        };
      };
    };

    git.signingKey = "~/.ssh/far-from-home.pub";
    ssh.identityKey = "~/.ssh/far-from-home";

    opencode.server = {
      enable = false;
      hostname = "0.0.0.0";
      port = 4096;
    };

    system.autoUpgrade = {
      enable = true;
      flake = "${config.nixConfigPath}#homelab";
      dates = "daily";
      randomizedDelaySec = "45min";
    };
  };
}
