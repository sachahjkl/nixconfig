_: {
  flake.nixosModules.filebrowserIntegration = {
    config,
    lib,
    ...
  }: let
    cfg = config.services.filebrowserIntegration;
    inherit (lib) mkEnableOption mkIf mkOption types;
  in {
    options.services.filebrowserIntegration = {
      enable = mkEnableOption "File Browser native service";

      port = mkOption {
        type = types.port;
        default = 8082;
        description = "Port File Browser listens on. 8082 is chosen to avoid common ports like 80, 443, 6969, and 8000.";
      };

      root = mkOption {
        type = types.str;
        description = "Root directory served by File Browser.";
      };
    };

    config = mkIf cfg.enable {
      services.filebrowser = {
        enable = true;
        settings = {
          address = "127.0.0.1";
          inherit (cfg) port root;
        };
      };
    };
  };
}
