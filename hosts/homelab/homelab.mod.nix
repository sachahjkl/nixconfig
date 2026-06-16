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
      self.nixosModules.clockinService
      self.nixosModules.lanblasterService
      self.nixosModules.ai
    ];

    userName = "sacha";
    fullName = "Sacha";
    homeDirectory = "/data/Home/sacha";
    nixConfigPath = "/data/Home/sacha/Projects/nixconfig";
    extraUserGroups = ["docker"];
    users.mutableUsers = lib.mkForce false;

    features.ai = {
      enable = true;
      handy.enable = false;
    };

    homelab = {
      lanInterface = "eno1";
      dataRoot = "/data";

      sops = {
        enable = true;
      };

      services = {
        hermesDashboard.enable = false;
        sachaHouse.enable = true;
        filebrowser.enable = true;
        lanblaster.enable = true;
        clockin = {
          enable = true;
          databaseDir = "/data/Services/clockin";
        };
      };
    };

    preferences.opencode.server = {
      enable = false;
      hostname = "0.0.0.0";
      port = 4096;
    };

    preferences.git.signingKey = "~/.ssh/far-from-home.pub";

    system.autoUpgrade = {
      enable = true;
      flake = "${config.nixConfigPath}#homelab";
      dates = "daily";
      randomizedDelaySec = "45min";
    };
  };
}
