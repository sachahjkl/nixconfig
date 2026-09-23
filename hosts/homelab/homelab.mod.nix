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
      self.nixosModules.server
      self.nixosModules.homelabLayout
      self.nixosModules.containerHost
      self.nixosModules.observabilityStack
      self.nixosModules.homelabShares
      self.nixosModules.resticBackup
      self.nixosModules.homelabSecrets
      self.nixosModules.reverseProxy
      self.nixosModules.hermesDashboard
      self.nixosModules.filebrowser
      self.nixosModules.webTerminal
      self.nixosModules.githubRunner
      self.nixosModules.nomadPlatform
      self.nixosModules.homelab-hardware
      self.nixosModules.homelabRoutes
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
      sops.enable = true;
    };

    services = {
      containerHost = {
        enable = true;
        dockerDataRoot = "/data/Docker/storage";
        sharedNetwork = "services";
      };

      observabilityStack = {
        enable = true;
        dataDir = "/data/Docker/appdata/observability";
        containerNetwork = "services";
        grafanaDomain = "grafana.sacha.house";
        otlpDomain = "otlp.sacha.house";
      };

      managedGithubRunners = {
        enable = true;
        sopsFile = self + /secrets/homelab.yaml;
        repositories.nixconfig = "https://github.com/sachahjkl/nixconfig";
        trustedRepositories = ["nixconfig"];
        labels = ["nixos" "nix" "homelab"];
      };

      hermesDashboard.enable = false;

      codexProxyIntegration = {
        enable = true;
        domain = "codex.sacha.house";
      };

      filebrowser = {
        enable = true;
        adminPasswordFile = config.sops.secrets."filebrowser/admin-password".path;
        settings = {
          address = "127.0.0.1";
          port = 8082;
          root = "/data";
        };
      };

      webTerminal = {
        enable = true;
        user = "sacha";
      };

      nomadPlatform = {
        enable = true;
        server = true;
        client = true;
        ingress = true;
        dataDir = "/data/Services/nomad";
        datacenter = "homelab";
        sopsFile = self + /secrets/homelab.yaml;
        interface = "ts0";
        namespaces = ["staging" "production" "demo"];
        nodeClass = "general";
        serverAddresses = ["100.106.51.80"];
        address = "100.106.51.80";
        githubActions = {
          enable = true;
          owner = "sachahjkl";
          audience = "nomad.sacha.house";
        };
      };

      nixCache = {
        enable = true;
        signingKeySopsFile = self + /secrets/homelab.yaml;
      };

      resticBackup = {
        enable = true;
        paths = [
          "/root"
          "/persist/var/lib/sops-nix"
          "/data/Secrets"
          "/data/Services"
          "/data/Docker/appdata"
          "/data/Docker/data/Secrets"
          "/data/Docker/storage/volumes"
          "/data/Home"
        ];
        excludes = [
          ".cache"
          ".npm"
          ".bun"
          ".cargo"
          ".rustup"
          "node_modules"
          ".git"
          "tmp"
          ".local/share/Trash"
          "appdata.bak"
        ];
      };
    };

    git.signingKey = "~/.ssh/far-from-home.pub";
    ssh.identityKey = "~/.ssh/far-from-home";

    system.autoUpgrade = {
      enable = true;
      flake = "${config.nixConfigPath}#homelab";
      dates = "daily";
      randomizedDelaySec = "45min";
    };
  };
}
