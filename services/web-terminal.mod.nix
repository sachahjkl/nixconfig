_: {
  flake.nixosModules.webTerminal = {
    config,
    lib,
    ...
  }: let
    cfg = config.services.webTerminal;
    inherit (lib) mkEnableOption mkIf mkOption types;
  in {
    options.services.webTerminal = {
      enable = mkEnableOption "browser terminal";

      user = mkOption {
        type = types.str;
        description = "User account that owns terminal sessions.";
      };

      port = mkOption {
        type = types.port;
        default = 7681;
        description = "Local ttyd port.";
      };
    };

    config = mkIf cfg.enable {
      services.ttyd = {
        enable = true;
        interface = "127.0.0.1";
        inherit (cfg) port user;
        checkOrigin = true;
        maxClients = 2;
        terminalType = "xterm-256color";
        writeable = true;
        entrypoint = [
          (lib.getExe config.users.users.${cfg.user}.shell)
          "--login"
        ];
        clientOptions = {
          cursorBlink = "true";
          cursorStyle = "bar";
          fontFamily = "Berkeley Mono, JetBrains Mono, monospace";
          fontSize = "15";
          scrollback = "10000";
          theme = builtins.toJSON {
            background = "#0d1117";
            foreground = "#e6edf3";
            cursor = "#58a6ff";
            selectionBackground = "#264f78";
          };
        };
      };

      systemd.services.ttyd.serviceConfig = {
        WorkingDirectory = config.users.users.${cfg.user}.home;
        UMask = "0077";
      };
    };
  };
}
