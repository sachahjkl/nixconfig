_: {
  flake.nixosModules.xdgStubs = {config, ...}: {
    hjem.users.${config.userName} = {
      xdg = {
        config.files = {
          "ripgrep".type = "directory";
          "ripgrep/config".text = "";
        };

        state.files = {
          "less".type = "directory";
          "python".type = "directory";
        };

        data.files = {
          "cargo".type = "directory";
          "gradle".type = "directory";
        };
      };

      environment.sessionVariables = {
        CARGO_HOME = "${config.homeDirectory}/.local/share/cargo";
        GRADLE_USER_HOME = "${config.homeDirectory}/.local/share/gradle";
        RIPGREP_CONFIG_PATH = "${config.homeDirectory}/.config/ripgrep/config";
        LESSHISTFILE = "${config.homeDirectory}/.local/state/less/history";
        PYTHON_HISTORY = "${config.homeDirectory}/.local/state/python/history";
      };
    };

    persist.user.directories = [
      ".local/share/cargo"
      ".local/share/gradle"
    ];
  };
}
