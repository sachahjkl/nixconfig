{
  self,
  inputs,
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
      self.nixosModules.filebrowser
      self.nixosModules.webTerminal
      self.nixosModules.githubRunner
      self.nixosModules.nomadPlatform
      self.nixosModules.k3sPlatform
      self.nixosModules.containerRegistry
      self.nixosModules.openbaoPlatform
      self.nixosModules.homelab-hardware
      self.nixosModules.homelabRoutes
      self.nixosModules.nixCache
      self.nixosModules.modusCache
      self.nixosModules.windowsVm
    ];

    extraUserGroups = ["docker"];
    homeDirectory = "/data/Home/sacha";
    # /tmp is already on the persistent @data-tmp Btrfs subvolume.
    persist.tmpDisk.enable = false;

    ai = {
      enable = true;
      hex.enable = false;
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

    homelab.sops.enable = true;
    rex.server.enable = true;

    services = {
      containerHost = {
        enable = true;
        dockerDataRoot = "/data/Docker/storage";
      };

      observabilityStack = {
        enable = true;
        dataDir = "/data/Docker/appdata/observability";
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

      hardwareWatchdog.enable = true;

      thermalGuard = {
        enable = true;
        criticalAction = "poweroff";
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

      # Windows 11 for the Windows builds and tests of gui_toolkit (docs/md/windows-vm.md).
      windowsVm = {
        enable = true;
        dataDir = "/data/VMs/windows";
        address = "100.106.51.80";
      };

      nixCache = {
        enable = true;
        signingKeySopsFile = self + /secrets/homelab.yaml;
      };

      modusCache = {
        enable = true;
        dataDir = "/data/modus-cache";
        port = 5010;
        statusPort = 5011;
        endpoint = "cache.modus.systems:5010";
        # The cache signing key of the publisher of modus: its release workflow
        # uploads the files of each release and the realisation of the test recipe.
        authorizedKeyFiles = ["${inputs.modus}/resources/keys/cache_signing_key.public"];
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

    systemd.services.restic-backup = {
      requires = ["openbao-snapshot.service" "sqlite-snapshots.service"];
      after = ["openbao-snapshot.service" "sqlite-snapshots.service"];
    };

    system.autoUpgrade = {
      enable = true;
      flake = "${config.nixConfigPath}#homelab";
      dates = "daily";
      randomizedDelaySec = "45min";
    };
  };
}
