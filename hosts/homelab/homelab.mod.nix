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
        observability = {
          enable = true;
          grafanaDomain = "grafana.homelab.sacha.house";
          otlpDomain = "otlp.homelab.sacha.house";
        };

        githubRunner = {
          enable = true;
          repositories = {
            acheteteper = "https://github.com/sachahjkl/acheteteper";
            albumator = "https://github.com/sachahjkl/albumator";
            chat = "https://github.com/sachahjkl/chat.sacha.house";
            client-serv-ipc = "https://github.com/sachahjkl/client_serv_ipc";
            cool = "https://github.com/sachahjkl/cool.sacha.house";
            dut-a2-expcom-disscog = "https://github.com/sachahjkl/dut_a2_expcom_disscog";
            dut-a2-mpa-auvergne = "https://github.com/sachahjkl/dut_a2_mpa_auvergne";
            dut-a2-pwebc-carte = "https://github.com/sachahjkl/dut_a2_pwebc_carte";
            froment-software = "https://github.com/sachahjkl/froment.software";
            grind-brother-grind = "https://github.com/sachahjkl/grind-brother-grind";
            htmx-go = "https://github.com/sachahjkl/htmx-go";
            js-canvas-experiment = "https://github.com/sachahjkl/js_canvas_experiment";
            kelio-rewrite = "https://github.com/sachahjkl/kelio-rewrite";
            nuitdelinfojb = "https://github.com/sachahjkl/nuitdelinfojb.github.io";
            old-site = "https://github.com/sachahjkl/old.sachahjkl.github.io";
            sacha-house = "https://github.com/sachahjkl/sacha.house";
            sachahjkl-site = "https://github.com/sachahjkl/sachahjkl.github.io";
            sqrt-eth-site = "https://github.com/sachahjkl/sqrt-eth.github.io";
            wthhyb = "https://github.com/sachahjkl/wthhyb.sacha.house";
          };
        };
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
