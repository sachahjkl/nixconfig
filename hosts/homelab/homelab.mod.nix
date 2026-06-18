{
  self,
  lib,
  ...
}: let
  homeDirectory = "/data/Home/sacha/";
in
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
    extraUserGroups = ["docker"];
    users.mutableUsers = lib.mkForce false;
    inherit homeDirectory;
    nixConfigPath = homeDirectory + "Projects/nixconfig/";

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

    preferences = {
      git.signingKey = "~/.ssh/far-from-home.pub";
      ssh.identityKey = "~/.ssh/far-from-home";

      opencode.server = {
        enable = false;
        hostname = "0.0.0.0";
        port = 4096;
      };
    };

    system.autoUpgrade = {
      enable = true;
      flake = "${config.nixConfigPath}#homelab";
      dates = "daily";
      randomizedDelaySec = "45min";
    };
  };
}
