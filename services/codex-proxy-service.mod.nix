{inputs, ...}: {
  flake.nixosModules.codexProxyService = {
    config,
    lib,
    ...
  }: let
    inherit
      (lib)
      mkDefault
      mkEnableOption
      mkIf
      mkOption
      types
      ;
    cfg = config.homelab.services.codexProxy;
  in {
    imports = [inputs.ai-api-proxy.nixosModules.default];

    options.homelab.services.codexProxy = {
      enable = mkEnableOption "codex.sacha.house reverse proxy";

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Host address the Codex proxy listens on.";
      };

      port = mkOption {
        type = types.port;
        default = 8083;
        description = "Port the Codex proxy listens on.";
      };

      proxyTokenFile = mkOption {
        type = types.path;
        default = config.sops.secrets."codex-proxy/token".path;
        description = "File that contains the shared proxy token.";
      };

      oauthCredentialFile = mkOption {
        type = types.path;
        default = config.sops.secrets."codex-proxy/oauth".path;
        description = "File that contains the seed ChatGPT OAuth credential.";
      };
    };

    config = mkIf cfg.enable {
      services.codex-proxy = {
        enable = true;
        listenAddress = "${cfg.host}:${toString cfg.port}";
        inherit (cfg) oauthCredentialFile proxyTokenFile;
      };

      homelab.proxy.hosts."codex.sacha.house" = {
        upstreamHost = mkDefault cfg.host;
        upstreamPort = mkDefault cfg.port;
        websockets = mkDefault true;
        extraConfig = ''
          proxy_buffering off;
          proxy_read_timeout 3600s;
          proxy_send_timeout 3600s;
        '';
      };
    };
  };
}
