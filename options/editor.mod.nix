{
  config.flake.lib.editors = {
    neovim = {
      id = "neovim";
      command = "nvim";
      commandWithFile = "nvim";
      commandWithLine = "nvim +{line} {file}";
      commandWithLocation = "nvim +\"call cursor({line}, {column})\" {file}";
      watchCommand = "nvim";
      desktop = "default-editor.desktop";
      icon = "nvim";
      needsTerminal = true;
    };

    lite-xl = {
      id = "lite-xl";
      command = "lite-xl";
      commandWithFile = "lite-xl";
      # Lite XL opens a file but takes no line or column argument.
      commandWithLine = "lite-xl {file}";
      commandWithLocation = "lite-xl {file}";
      watchCommand = "lite-xl";
      desktop = "default-editor.desktop";
      icon = "lite-xl";
      needsTerminal = false;
    };

    vscode = {
      id = "vscode";
      command = "code";
      commandWithFile = "code";
      commandWithLine = "code --goto {file}:{line}";
      commandWithLocation = "code --goto {file}:{line}:{column}";
      watchCommand = "code --wait";
      desktop = "default-editor.desktop";
      icon = "vscode";
      needsTerminal = false;
    };
  };
}
