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
    cfg = config.services.codexProxyIntegration;
  in {
    imports = [inputs.ai-api-proxy.nixosModules.default];

    options.services.codexProxyIntegration = {
      enable = mkEnableOption "Codex API proxy integration";

      domain = mkOption {
        type = types.str;
        description = "Domain routed to the Codex API proxy.";
      };

      publicUrl = mkOption {
        type = types.str;
        default = "https://${cfg.domain}";
        description = "Public URL advertised by the Codex API proxy.";
      };

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
        inherit (cfg) publicUrl;
        inherit (cfg) oauthCredentialFile proxyTokenFile;
      };

      services.reverseProxy.hosts.${cfg.domain} = {
        upstreamHost = mkDefault cfg.host;
        upstreamPort = mkDefault cfg.port;
      };
    };
  };
}
