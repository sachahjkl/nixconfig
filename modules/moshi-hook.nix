{
  self,
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  cfg = config.moshi;
  hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
  hasPersistDirs = lib.hasAttrByPath ["persist" "user" "directories"] options;
  hasSopsSecrets = lib.hasAttrByPath ["sops" "secrets"] options;
  hasUserName = lib.hasAttrByPath ["userName"] options;
  moshiHookPkg = self.packages.${pkgs.stdenv.hostPlatform.system}.moshiHook;
  pairingTokenPath = "/run/secrets/moshi-pairing-token";
  syncProjects = lib.concatStringsSep "\n" (
    map (projectRoot: ''
      if [ -d ${lib.escapeShellArg projectRoot} ]; then
        (
          cd ${lib.escapeShellArg projectRoot}
          ${lib.getExe moshiHookPkg} install
        )
      fi
    '')
    cfg.projectRoots
  );
  moshiSyncHooks = pkgs.writeShellScriptBin "moshi-sync-hooks" ''
    set -eu

    ${lib.getExe moshiHookPkg} install
    ${syncProjects}
  '';
  moshiPair = pkgs.writeShellScriptBin "moshi-pair" ''
    set -eu

    if [ "$#" -lt 1 ]; then
      printf 'usage: moshi-pair <pairing-token>\n' >&2
      exit 1
    fi

    ${lib.getExe moshiHookPkg} pair --token "$1"
    ${lib.getExe moshiSyncHooks}
    systemctl --user restart moshi-hook.service
    ${lib.getExe moshiHookPkg} status || true
  '';
  moshiPairFromSecret = pkgs.writeShellScriptBin "moshi-pair-from-secret" ''
    set -eu

    if [ ! -r ${lib.escapeShellArg pairingTokenPath} ]; then
      printf 'missing Moshi pairing token secret at %s\n' ${lib.escapeShellArg pairingTokenPath} >&2
      exit 1
    fi

    ${lib.getExe moshiPair} "$(tr -d '\n' < ${lib.escapeShellArg pairingTokenPath})"
  '';
in {
  imports = [self.nixosModules.sops];

  options.moshi = {
    enable = lib.mkEnableOption "Moshi hook daemon and helpers";

    service.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to run moshi-hook serve as a user service.";
    };

    projectRoots = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [config.nixConfigPath];
      defaultText = lib.literalExpression "[ config.nixConfigPath ]";
      description = "Project roots where moshi-sync-hooks should install the OpenCode plugin.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      environment.systemPackages = [
        moshiHookPkg
        moshiPair
        moshiSyncHooks
        moshiPairFromSecret
      ];

      systemd.user.services.moshi-hook = lib.mkIf cfg.service.enable {
        description = "Moshi hook daemon";
        wantedBy = ["default.target"];
        after = ["network.target"];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${lib.getExe moshiHookPkg} serve";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    }

    (lib.optionalAttrs hasPersistDirs {
      persist.user.directories = [
        ".config/moshi"
      ];
    })

    (lib.optionalAttrs (hasSopsSecrets && hasUserName) {
      sops.secrets."ai/moshi-pairing-token" = {
        sopsFile = self + /secrets/shared.yaml;
        path = pairingTokenPath;
        owner = config.userName;
        group = "users";
        mode = "0400";
      };
    })

    (lib.optionalAttrs (hasHjemUsers && hasUserName) {
      hjem.users.${config.userName}.rum.programs.fish.functions = {
        # OpenCode plugin setup is project-scoped, so keep a helper that can
        # refresh user hooks and this repo's plugin after pairing or upgrades.
        moshi-sync = ''
          ${lib.getExe moshiSyncHooks}
        '';

        moshi-pair = ''
          ${lib.getExe moshiPair} $argv
        '';

        moshi-pair-from-secret = ''
          ${lib.getExe moshiPairFromSecret}
        '';
      };
    })
  ]);
}
