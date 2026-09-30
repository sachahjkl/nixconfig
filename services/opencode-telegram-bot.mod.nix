{self, ...}: {
  perSystem = {pkgs, ...}: {
    packages.opencodeTelegramBot = pkgs.buildNpmPackage rec {
      pname = "opencode-telegram-bot";
      version = "0.26.1";

      src = pkgs.fetchFromGitHub {
        owner = "grinev";
        repo = "opencode-telegram-bot";
        rev = "v${version}";
        hash = "sha256-tadPEfxdaQCVGWTkJsVBYU9SQNQQ0mv500qWPxpF6g4=";
      };

      npmDepsHash = "sha256-DNU/F6Bkb9ZcVc5BdArTSdytCLsNKKkBuRjYARN32uE=";

      meta = {
        description = "Telegram client for OpenCode";
        homepage = "https://github.com/grinev/opencode-telegram-bot";
        license = pkgs.lib.licenses.mit;
        mainProgram = "opencode-telegram";
      };
    };
  };

  flake.nixosModules.opencodeTelegramBot = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkOption types;
    cfg = config.services.opencodeTelegramBot;
    package = self.packages.${pkgs.stdenv.hostPlatform.system}.opencodeTelegramBot;
    launcher = pkgs.writeShellScript "opencode-telegram-bot" ''
      set -eu
      export TELEGRAM_BOT_TOKEN="$(cat "$CREDENTIALS_DIRECTORY/telegram-token")"
      export OPENCODE_SERVER_PASSWORD="$(cat "$CREDENTIALS_DIRECTORY/opencode-password")"
      exec ${lib.getExe package} start
    '';
  in {
    options.services.opencodeTelegramBot = {
      enable = mkEnableOption "OpenCode Telegram bot";

      user = mkOption {
        type = types.str;
        default = config.userName;
        description = "User that runs the OpenCode Telegram bot.";
      };

      telegramTokenFile = mkOption {
        type = types.str;
        description = "File containing the Telegram bot token.";
      };

      allowedUserId = mkOption {
        type = types.str;
        description = "Numeric Telegram user ID allowed to use the bot.";
      };

      opencodePasswordFile = mkOption {
        type = types.str;
        description = "File containing the OpenCode server password.";
      };

      opencodeUrl = mkOption {
        type = types.str;
        default = "http://127.0.0.1:4096";
        description = "URL of the OpenCode server.";
      };

      model = {
        provider = mkOption {
          type = types.str;
          default = "openai";
          description = "Default OpenCode model provider.";
        };

        id = mkOption {
          type = types.str;
          default = "gpt-5.6-sol";
          description = "Default OpenCode model ID.";
        };
      };
    };

    config = mkIf cfg.enable {
      systemd.services.opencode-telegram-bot = {
        description = "OpenCode Telegram bot";
        wantedBy = ["multi-user.target"];
        after = ["network-online.target" "opencode.service"];
        wants = ["network-online.target"];
        requires = ["opencode.service"];
        environment = {
          HOME = config.users.users.${cfg.user}.home;
          BOT_LOCALE = "fr";
          OPEN_BROWSER_ROOTS = "${config.users.users.${cfg.user}.home}/Projects";
          OPENCODE_API_URL = cfg.opencodeUrl;
          OPENCODE_MODEL_ID = cfg.model.id;
          OPENCODE_MODEL_PROVIDER = cfg.model.provider;
          OPENCODE_SERVER_USERNAME = "opencode";
          OPENCODE_SERVER_VERSION = "v2";
          TELEGRAM_ALLOWED_USER_ID = cfg.allowedUserId;
        };
        serviceConfig = {
          User = cfg.user;
          Group = "users";
          ExecStart = launcher;
          LoadCredential = [
            "telegram-token:${cfg.telegramTokenFile}"
            "opencode-password:${cfg.opencodePasswordFile}"
          ];
          NoNewPrivileges = true;
          PrivateTmp = true;
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
  };
}
