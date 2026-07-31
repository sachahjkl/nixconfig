_: {
  flake.nixosModules.xdgStubs = {config, ...}: {
    hjem.users.${config.userName} = {
      xdg = {
        config.files = {
          "ripgrep/config".text = "";
        };

        state.files = {
          "less".type = "directory";
          "python".type = "directory";
        };

        data.files."go".type = "directory";
      };

      environment.sessionVariables = {
        GOPATH = "${config.homeDirectory}/.local/share/go";
        RIPGREP_CONFIG_PATH = "${config.homeDirectory}/.config/ripgrep/config";
        LESSHISTFILE = "${config.homeDirectory}/.local/state/less/history";
        PYTHON_HISTORY = "${config.homeDirectory}/.local/state/python/history";
      };
    };

    persist.user.directories = [
      ".local/share/go"
    ];
  };
}
