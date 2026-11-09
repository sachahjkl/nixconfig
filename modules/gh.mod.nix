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
    # The shared token from sops is the fallback: a login stored with
    # `gh auth login` comes first. The fine-grained token cannot open issues
    # or pull requests on other people's public repositories.
    wrappedGh = pkgs.writeShellScriptBin "gh" ''
      if ! env -u GH_TOKEN -u GITHUB_TOKEN ${lib.getExe pkgs.gh} auth token --hostname github.com >/dev/null 2>&1 \
        && [ -r ${lib.escapeShellArg tokenPath} ]; then
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
        environment.sessionVariables.NIX_USER_CONF_FILES = config.sops.templates."nix-github.conf".path;

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

        sops.templates."nix-github.conf" = {
          content = ''
            access-tokens = github.com=${config.sops.placeholder."github/gh-cli"}
          '';
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
