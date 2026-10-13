{self, ...}: {
  flake.nixosModules.cloudflareCli = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    cfg = config.cloudflareCli;
    hasSopsSecrets = lib.hasAttrByPath ["sops" "secrets"] options;
    hasUserName = lib.hasAttrByPath ["userName"] options;
    sharedSopsEnabled = lib.attrByPath ["sharedSops" "enable"] false config;

    # `cf` reads CLOUDFLARE_API_TOKEN; a token already set in the environment wins
    # over the sops-managed file.
    wrap = name:
      pkgs.writeShellScriptBin name ''
        if [ -z "''${CLOUDFLARE_API_TOKEN:-}" ] && [ -r ${lib.escapeShellArg cfg.tokenPath} ]; then
          CLOUDFLARE_API_TOKEN="$(< ${lib.escapeShellArg cfg.tokenPath})"
          export CLOUDFLARE_API_TOKEN
        fi
        export CF_SEND_TELEMETRY="''${CF_SEND_TELEMETRY:-false}"
        exec ${lib.getExe cfg.package} "$@"
      '';
  in {
    options.cloudflareCli = {
      enable = lib.mkEnableOption "the Cloudflare CLI (cf) with the shared Cloudflare API token" // {default = true;};

      package = lib.mkOption {
        type = lib.types.package;
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.cf;
        defaultText = lib.literalExpression "self.packages.\${system}.cf";
        description = "Cloudflare CLI package.";
      };

      sopsFile = lib.mkOption {
        type = lib.types.path;
        default = self + /secrets/shared.yaml;
        description = "SOPS file containing the Cloudflare API token.";
      };

      sopsKey = lib.mkOption {
        type = lib.types.str;
        default = "cloudflare/dns";
        description = "Key of the Cloudflare API token in the SOPS file.";
      };

      tokenPath = lib.mkOption {
        type = lib.types.str;
        default = "/run/secrets/cloudflare-cli-token";
        description = "Runtime file holding the Cloudflare API token, readable by the primary user.";
      };
    };

    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        environment.systemPackages = [
          (wrap "cf")
          (wrap "cloudflare")
        ];
      }

      (lib.optionalAttrs (hasSopsSecrets && hasUserName) {
        sops.secrets."cloudflare/cli" = lib.mkIf sharedSopsEnabled {
          inherit (cfg) sopsFile;
          key = cfg.sopsKey;
          path = cfg.tokenPath;
          owner = config.userName;
          group = "users";
          mode = "0400";
        };
      })
    ]);
  };
}
