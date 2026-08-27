{self, ...}: {
  flake.nixosModules.gh = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    hasPersistDirs = lib.hasAttrByPath ["persist" "user" "directories"] options;
    hasSopsSecrets = lib.hasAttrByPath ["sops" "secrets"] options;
    hasUserName = lib.hasAttrByPath ["userName"] options;
    tokenPath = "/run/secrets/github-far-from-home-pat";
    wrappedGh = pkgs.writeShellScriptBin "gh" ''
      if [ -r ${lib.escapeShellArg tokenPath} ]; then
        export GH_TOKEN="$(cat ${lib.escapeShellArg tokenPath})"
        export GITHUB_TOKEN="$GH_TOKEN"
      fi

      exec ${lib.getExe pkgs.gh} "$@"
    '';
  in {
    imports = [self.nixosModules.sops];

    config = lib.mkMerge [
      {
        environment.systemPackages = [wrappedGh];
      }

      (lib.optionalAttrs (hasSopsSecrets && hasUserName) {
        sops.secrets."github/gh-cli" = {
          sopsFile = builtins.path {
            path = self + /secrets/shared.yaml;
            name = "shared-secrets.yaml";
          };
          path = tokenPath;
          owner = config.userName;
          group = "users";
          mode = "0400";
        };
      })

      (lib.optionalAttrs hasPersistDirs {
        persist.user.directories = [
          ".config/gh"
          ".local/state/gh"
        ];
      })
    ];
  };
}
