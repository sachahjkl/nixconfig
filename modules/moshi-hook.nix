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
  homeDirectory = lib.attrByPath ["homeDirectory"] "" config;
  moshiHookPkg = self.packages.${pkgs.stdenv.hostPlatform.system}.moshiHook;
  # Moshi still ships a V1 OpenCode plugin. Install our V2 port over it until
  # moshi-hook generates the V2 shape itself.
  moshiOpencodePlugin = self + /modules/ai/plugins/moshi-hooks.ts;
  installOpencodePlugin =
    lib.optionalString (homeDirectory != "")
    "${pkgs.coreutils}/bin/install -Dm644 ${moshiOpencodePlugin} ${homeDirectory}/.config/opencode/plugins/moshi-hooks.ts";
  pairingTokenPath = "/run/secrets/moshi-pairing-token";
  moshiSyncHooks = pkgs.writeShellScriptBin "moshi-sync-hooks" ''
    set -eu

    ${lib.getExe moshiHookPkg} install
    ${installOpencodePlugin}
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

  options.moshi.enable = lib.mkEnableOption "Moshi hook daemon and helpers";

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      environment.systemPackages = [
        moshiHookPkg
        moshiPair
        moshiSyncHooks
        moshiPairFromSecret
      ];

      systemd.user.services.moshi-hook = {
        description = "Moshi hook daemon";
        wantedBy = ["default.target"];
        after = ["network.target"];
        unitConfig.ConditionUser = config.userName;
        serviceConfig = {
          Type = "simple";
          ExecStartPre = lib.getExe moshiSyncHooks;
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
        sopsFile = builtins.path {
          path = self + /secrets/shared.yaml;
          name = "shared-secrets.yaml";
        };
        path = pairingTokenPath;
        owner = config.userName;
        group = "users";
        mode = "0400";
      };
    })

    (lib.optionalAttrs (hasHjemUsers && hasUserName) {
      hjem.users.${config.userName}.rum.programs.fish.functions = {
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
