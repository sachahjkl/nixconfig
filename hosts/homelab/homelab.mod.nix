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
      self.nixosModules.homelab
      self.nixosModules.homelab-hardware
      self.nixosModules.homelabProxyHosts
    ];

    userName = "sacha";
    fullName = "Sacha";
    homeDirectory = "/data/Home/sacha";
    nixConfigPath = "/data/Home/sacha/Projects/nixconfig";
    extraUserGroups = ["docker"];
    users.mutableUsers = lib.mkForce true;

    homelab = {
      lanInterface = "eno1";
      dataRoot = "/data";

      sops = {
        enable = false;
        defaultSopsFile = null;
      };

      services = {
        hermesDashboard.enable = true;
        sachaHouse.enable = true;
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
