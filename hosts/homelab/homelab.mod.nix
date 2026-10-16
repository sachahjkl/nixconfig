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
      self.nixosModules.opencodeTelegramBot
      self.nixosModules.homelabLayout
      self.nixosModules.containerHost
      self.nixosModules.observabilityStack
      self.nixosModules.homelabShares
      self.nixosModules.resticBackup
      self.nixosModules.sqliteSnapshots
      self.nixosModules.homelabSecrets
      self.nixosModules.reverseProxy
      self.nixosModules.hermesDashboard
      self.nixosModules.filebrowser
      self.nixosModules.webTerminal
      self.nixosModules.githubRunner
      self.nixosModules.nomadPlatform
      self.nixosModules.k3sPlatform
      self.nixosModules.containerRegistry
      self.nixosModules.openbaoPlatform
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

    opencode.server = {
      enable = true;
      passwordFile = config.sops.secrets."opencode/server-password".path;
      cors = ["https://ai.sacha.house"];
    };

    services.opencodeTelegramBot = {
      enable = true;
      telegramTokenFile = config.sops.secrets."opencode-telegram/bot-token".path;
      allowedUserId = "1532149944";
      opencodePasswordFile = config.sops.secrets."opencode/server-password".path;
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

      hardwareWatchdog.enable = true;

      thermalGuard = {
        enable = true;
        criticalAction = "poweroff";
      };

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
        ghcrPull.enable = true;
        nodeClass = "general";
        serverAddresses = ["100.106.51.80"];
        address = "100.106.51.80";
        githubActions = {
          enable = true;
          owners = ["sachahjkl" "petitpecule"];
          audience = "nomad.sacha.house";
        };
      };

      k3sPlatform = {
        enable = true;
        dataDir = "/data/Services/k3s";
        apiAddress = "100.106.51.80";
        apiInterface = "ts0";
      };

      containerRegistry = {
        enable = true;
        domain = "registry.sacha.house";
        address = "100.106.51.80";
        interface = "ts0";
        dataDir = "/data/Services/registry";
        acmeEmail = "sacha@sacha.house";
        cloudflareSopsFile = self + /secrets/shared.yaml;
        credentialsSopsFile = self + /secrets/homelab.yaml;
      };

      nixCache = {
        enable = true;
        signingKeySopsFile = self + /secrets/homelab.yaml;
      };

      openbaoPlatform = {
        enable = true;
        domain = "bao.sacha.house";
        address = "100.106.51.80";
        interface = "ts0";
        dataDir = "/data/Services/openbao";
        secretDir = "/data/Secrets/openbao";
        snapshotDir = "/data/Backups/openbao";
        acmeEmail = "sacha@sacha.house";
        sopsFile = self + /secrets/shared.yaml;
      };

      resticBackup = {
        enable = true;
        paths = [
          "/root"
          "/persist/var/lib/sops-nix"
          "/data/Secrets"
          "/data/Backups/openbao"
          "/data/Backups/sqlite"
          "/data/Services"
          "/data/Docker/appdata"
          "/data/Docker/data/Secrets"
          "/data/Docker/storage/volumes"
          "/data/Home"
        ];
        excludes = [
          "/data/Services/openbao/raft"
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
          # k3s: images, kubelet state and logs are rebuilt; the server database and volumes stay backed up.
          "/data/Services/k3s/state/agent"
          "/data/Services/k3s/state/data"
          "/data/Services/k3s/kubelet"
          "/data/Services/k3s/pod-logs"
          # Registry images are rebuilt from their repositories.
          "/data/Services/registry"
        ];
      };

      # Live SQLite databases of Nomad applications, copied consistently before each Restic run.
      sqliteSnapshots = {
        enable = true;
        directory = "/data/Backups/sqlite";
        databases.petitpecule = "/data/Services/nomad/volumes/*/petitpecule.db";
      };
    };

    git.signingKey = "~/.ssh/far-from-home.pub";
    systemd.services.restic-backup = {
      requires = ["openbao-snapshot.service" "sqlite-snapshots.service"];
      after = ["openbao-snapshot.service" "sqlite-snapshots.service"];
    };
    ssh.identityKey = "~/.ssh/far-from-home";

    system.autoUpgrade = {
      enable = true;
      flake = "${config.nixConfigPath}#homelab";
      dates = "daily";
      randomizedDelaySec = "45min";
    };
  };
}
