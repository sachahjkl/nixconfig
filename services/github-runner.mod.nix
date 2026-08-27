{self, ...}: {
  flake.nixosModules.githubRunner = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.homelab.services.githubRunner;
    runnerUser = "github-runner";
    trustedRunnerUser = "github-runner-nixconfig";
    secretName = "github/actions-runner";
    runnerContainersConf = pkgs.writeText "github-runner-containers.conf" ''
      [engine]
      cgroup_manager = "cgroupfs"
      events_logger = "file"
    '';
  in {
    imports = [self.nixosModules.sops];

    options.homelab.services.githubRunner = {
      enable = lib.mkEnableOption "GitHub Actions runner for homelab CI";

      repositories = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        example.git-migrate = "https://github.com/owner/git-migrate";
        description = "Repository URLs where separate runner instances are registered.";
      };
    };

    config = lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.repositories != {};
          message = "homelab.services.githubRunner.repositories must not be empty when the runner is enabled.";
        }
      ];

      users = {
        groups.${runnerUser} = {};
        users = {
          ${runnerUser} = {
            isSystemUser = true;
            group = runnerUser;
            home = "/var/lib/github-runner";
            homeMode = "0750";
            createHome = true;
            subUidRanges = [
              {
                startUid = 100000;
                count = 65536;
              }
            ];
            subGidRanges = [
              {
                startGid = 100000;
                count = 65536;
              }
            ];
          };
          ${trustedRunnerUser} = {
            isSystemUser = true;
            group = runnerUser;
          };
        };
      };

      nix.settings.trusted-users = [trustedRunnerUser];

      virtualisation.podman = {
        enable = true;
        dockerCompat = false;
      };

      programs.nix-ld.enable = true;

      sops.secrets.${secretName} = {
        sopsFile = builtins.path {
          path = self + /secrets/homelab.yaml;
          name = "homelab-secrets.yaml";
        };
        owner = runnerUser;
        group = runnerUser;
        mode = "0440";
      };

      services.github-runners =
        lib.mapAttrs (repositoryName: url: let
          serviceUser =
            if repositoryName == "nixconfig"
            then trustedRunnerUser
            else runnerUser;
        in {
          enable = true;
          name = "homelab-${repositoryName}";
          inherit url;
          tokenFile = config.sops.secrets.${secretName}.path;
          tokenType = "access";
          user = serviceUser;
          group = runnerUser;
          extraPackages = [
            config.virtualisation.podman.package
            pkgs.cachix
          ];
          extraEnvironment = {
            CONTAINERS_CONF_OVERRIDE = runnerContainersConf;
            HOME = "%S/github-runner/${repositoryName}";
            TMPDIR = "%S/github-runner/${repositoryName}";
            XDG_CACHE_HOME = "%S/github-runner/${repositoryName}/.cache";
            XDG_DATA_HOME = "%S/github-runner/${repositoryName}/.local/share";
            XDG_RUNTIME_DIR = "%t/github-runner/${repositoryName}";
          };
          extraLabels = [
            "nixos"
            "nix"
            "homelab"
          ];
          serviceOverrides = {
            CapabilityBoundingSet = lib.mkForce "~";
            NoNewPrivileges = lib.mkForce false;
            PrivateDevices = lib.mkForce false;
            PrivateMounts = lib.mkForce false;
            PrivateTmp = lib.mkForce false;
            PrivateUsers = lib.mkForce false;
            ProtectClock = lib.mkForce false;
            ProtectControlGroups = lib.mkForce false;
            ProtectHome = lib.mkForce false;
            ProtectHostname = lib.mkForce false;
            ProtectKernelLogs = lib.mkForce false;
            ProtectKernelModules = lib.mkForce false;
            ProtectKernelTunables = lib.mkForce false;
            ProtectProc = lib.mkForce "default";
            ReadWritePaths = [
              "/tmp"
              "/var/tmp"
            ];
            Restart = lib.mkForce "on-failure";
            RestartSec = 5;
            RestrictNamespaces = lib.mkForce false;
            RestrictSUIDSGID = lib.mkForce false;
            SystemCallFilter = lib.mkForce [];
          };
        })
        cfg.repositories;
    };
  };
}
