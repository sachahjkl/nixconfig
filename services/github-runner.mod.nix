{self, ...}: {
  flake.nixosModules.githubRunner = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    cfg = config.homelab.services.githubRunner;
    runnerUser = "github-runner";
    secretName = "github/actions-runner";
    hasPersistDirs = lib.hasAttrByPath ["persist" "system" "directories"] options;
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

    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.repositories != {};
            message = "homelab.services.githubRunner.repositories must not be empty when the runner is enabled.";
          }
        ];

        users.users.${runnerUser} = {
          isSystemUser = true;
          group = runnerUser;
          home = "/var/lib/github-runner";
          createHome = true;
          linger = true;
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
        users.groups.${runnerUser} = {};

        virtualisation.podman = {
          enable = true;
          dockerCompat = false;
        };

        programs.nix-ld.enable = true;

        sops.secrets.${secretName} = {
          sopsFile = self + /secrets/homelab.yaml;
          owner = runnerUser;
          group = runnerUser;
          mode = "0400";
        };

        services.github-runners =
          lib.mapAttrs (repositoryName: url: {
            enable = true;
            name = "homelab-${repositoryName}";
            inherit url;
            tokenFile = config.sops.secrets.${secretName}.path;
            tokenType = "access";
            user = runnerUser;
            group = runnerUser;
            extraPackages = [
              config.virtualisation.podman.package
              pkgs.cachix
            ];
            extraLabels = [
              "nixos"
              "nix"
              "homelab"
            ];
            serviceOverrides = {
              CapabilityBoundingSet = [
                "CAP_SETGID"
                "CAP_SETUID"
              ];
              NoNewPrivileges = lib.mkForce false;
              PrivateUsers = lib.mkForce false;
              ProtectProc = lib.mkForce "default";
              Restart = lib.mkForce "on-failure";
              RestartSec = 5;
              RestrictNamespaces = lib.mkForce false;
              RestrictSUIDSGID = lib.mkForce false;
              SystemCallFilter = lib.mkForce [];
            };
          })
          cfg.repositories;
      }

      (lib.optionalAttrs hasPersistDirs {
        persist.system.directories = ["/var/lib/github-runner"];
      })
    ]);
  };
}
