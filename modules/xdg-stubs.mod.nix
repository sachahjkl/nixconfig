_: {
  flake.nixosModules.xdgStubs = {config, ...}: {
    hjem.users.${config.userName} = {
      xdg = {
        config.files = {
          "aws".type = "directory";
          "claude-code".type = "directory";
          "codex".type = "directory";
          "ripgrep".type = "directory";
          "ripgrep/config".text = "";
          "sops/age".type = "directory";
          "ssh".type = "directory";
        };

        data.files = {
          "android".type = "directory";
          "cargo".type = "directory";
          "go".type = "directory";
          "gradle".type = "directory";
        };

        state.files = {
          "less".type = "directory";
          "node".type = "directory";
          "python".type = "directory";
          "sqlite".type = "directory";
        };
      };

      environment.sessionVariables = {
        ANDROID_USER_HOME = "${config.homeDirectory}/.local/share/android";
        AWS_CONFIG_FILE = "${config.homeDirectory}/.config/aws/config";
        AWS_SHARED_CREDENTIALS_FILE = "${config.homeDirectory}/.config/aws/credentials";
        CLAUDE_CONFIG_DIR = "${config.homeDirectory}/.config/claude-code";
        CODEX_HOME = "${config.homeDirectory}/.config/codex";
        CARGO_HOME = "${config.homeDirectory}/.local/share/cargo";
        GOPATH = "${config.homeDirectory}/.local/share/go";
        GRADLE_USER_HOME = "${config.homeDirectory}/.local/share/gradle";
        RIPGREP_CONFIG_PATH = "${config.homeDirectory}/.config/ripgrep/config";
        LESSHISTFILE = "${config.homeDirectory}/.local/state/less/history";
        HISTFILE = "${config.homeDirectory}/.local/state/shell/history";
        NODE_REPL_HISTORY = "${config.homeDirectory}/.local/state/node/history";
        PYTHON_HISTORY = "${config.homeDirectory}/.local/state/python/history";
        SQLITE_HISTORY = "${config.homeDirectory}/.local/state/sqlite/history";
      };

      files.".ssh/config".text = ''
        Include ${config.homeDirectory}/.config/ssh/config
      '';
    };

    persist.user.directories = [
      ".config/aws"
      ".config/claude-code"
      ".config/codex"
      ".config/sops"
      ".local/share/android"
      ".local/share/cargo"
      ".local/share/go"
      ".local/share/gradle"
      ".local/state/shell"
    ];
  };
}
