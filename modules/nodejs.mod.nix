{self, ...}: {
  flake.nixosModules.nodejs = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
    hasHomeDirectory = lib.hasAttrByPath ["homeDirectory"] options;
    hasPersistDirectories = lib.hasAttrByPath ["persist" "user" "directories"] options;
    hasSharedSops = lib.hasAttrByPath ["sharedSops" "enable"] options;
    hasUserName = lib.hasAttrByPath ["userName"] options;
    npmTokenPath = "/run/secrets/npm-current-token";
    wrappedNpm = pkgs.writeShellScriptBin "npm" ''
      umask 077
      npmrc="$(mktemp)"
      trap 'rm -f "$npmrc"' EXIT
      ${lib.optionalString hasHomeDirectory ''
        printf '%s\n' 'prefix=${config.homeDirectory}/.local' > "$npmrc"
      ''}

      if [ -r ${lib.escapeShellArg npmTokenPath} ]; then
        printf '%s=%s\n' '//registry.npmjs.org/:_authToken' "$(cat ${lib.escapeShellArg npmTokenPath})" >> "$npmrc"
      fi

      NPM_CONFIG_USERCONFIG="$npmrc" ${lib.getExe' pkgs.nodejs "npm"} "$@"
    '';
  in {
    config = lib.mkMerge [
      {
        environment.systemPackages = [
          pkgs.nodejs
          pkgs.pnpm
          (lib.hiPrio wrappedNpm)
        ];
      }

      (lib.optionalAttrs (hasHjemUsers && hasHomeDirectory && hasUserName) {
        hjem.users.${config.userName} = {
          environment.sessionVariables.PNPM_HOME = "${config.homeDirectory}/.local/share/pnpm";
          files.".config/fish/conf.d/pnpm.fish".text = ''
            fish_add_path --global --move ${config.homeDirectory}/.local/share/pnpm/bin
          '';
          files.".npmrc".text = ''
            prefix=${config.homeDirectory}/.local
          '';
        };
      })

      (lib.mkIf (hasSharedSops && config.sharedSops.enable && hasUserName) {
        sops.secrets."npm/current-token-november-2026" = {
          sopsFile = builtins.path {
            path = self + /secrets/shared.yaml;
            name = "shared-secrets.yaml";
          };
          path = npmTokenPath;
          owner = config.userName;
          group = "users";
          mode = "0400";
        };
      })

      (lib.optionalAttrs hasPersistDirectories {
        persist.user.directories = [".local/share/pnpm"];
      })
    ];
  };
}
