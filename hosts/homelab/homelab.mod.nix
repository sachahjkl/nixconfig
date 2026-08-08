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
      self.nixosModules.herdrService
      self.nixosModules.albumatorService
      self.nixosModules.clockinService
      self.nixosModules.lanblasterService
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
        herdr.enable = true;
        hermesDashboard.enable = false;
        sachaHouse.enable = true;
        filebrowser.enable = true;
        lanblaster.enable = true;
        albumator = {
          enable = true;
          port = 3001;
          dataDir = "/data/Services/albumator";
        };
        clockin = {
          enable = true;
          port = 3002;
          databaseDir = "/data/Services/clockin";
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
