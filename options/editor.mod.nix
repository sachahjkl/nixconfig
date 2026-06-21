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
