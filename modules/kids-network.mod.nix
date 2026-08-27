{self, ...}: {
  flake.nixosModules.kidsNetwork = {
    config,
    lib,
    ...
  }: let
    cfg = config.kidsDesktop.network;
    tagFlag = "--advertise-tags=${lib.concatStringsSep "," cfg.tailscale.tags}";
  in {
    imports = [self.nixosModules.sops];

    options.kidsDesktop.network = {
      familyDns = {
        enable = lib.mkEnableOption "family-filtered DNS" // {default = true;};

        nameservers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "1.1.1.3"
            "1.0.0.3"
          ];
          description = "DNS servers that block malware and adult content.";
        };
      };

      tailscale = {
        authKeyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "File containing a reusable Tailscale auth key authorized for the device tags.";
        };

        hostName = lib.mkOption {
          type = lib.types.str;
          default = "kids-desktop";
          description = "Device name advertised to Tailscale.";
        };

        tags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = ["tag:kids-desktop"];
          description = "ACL tags advertised to Tailscale.";
        };
      };
    };

    config = lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.tailscale.tags != [] && builtins.all (lib.hasPrefix "tag:") cfg.tailscale.tags;
            message = "Every kids-desktop Tailscale tag must start with 'tag:'.";
          }
        ];

        services.tailscale = {
          authKeyFile =
            if cfg.tailscale.authKeyFile != null
            then cfg.tailscale.authKeyFile
            else config.sops.secrets."tailscale/user-authkey".path;
          enable = true;
          interfaceName = "ts0";
          useRoutingFeatures = "client";
          extraUpFlags = lib.mkAfter [
            "--hostname=${cfg.tailscale.hostName}"
            tagFlag
            "--ssh"
          ];
          extraSetFlags = lib.mkAfter [
            "--hostname=${cfg.tailscale.hostName}"
            tagFlag
            "--ssh"
          ];
        };

        networking.firewall.trustedInterfaces = [config.services.tailscale.interfaceName];

        sops = {
          defaultSopsFile = builtins.path {
            path = self + /secrets/shared.yaml;
            name = "shared-secrets.yaml";
          };
          defaultSopsFormat = "yaml";
          age = {
            keyFile = "/var/lib/sops-nix/key.txt";
            sshKeyPaths = [];
          };
          gnupg.sshKeyPaths = [];
          secrets."tailscale/user-authkey" = {
            owner = "root";
            group = "root";
            mode = "0400";
          };
        };
      }

      (lib.mkIf cfg.familyDns.enable {
        networking = {
          nameservers = cfg.familyDns.nameservers;
          networkmanager.dns = "none";
        };
      })
    ];
  };
}
