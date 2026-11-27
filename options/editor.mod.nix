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

    gnome-text-editor = {
      id = "gnome-text-editor";
      command = "gnome-text-editor";
      commandWithFile = "gnome-text-editor";
      # GNOME Text Editor opens a file but takes no line or column argument.
      commandWithLine = "gnome-text-editor {file}";
      commandWithLocation = "gnome-text-editor {file}";
      # A separate instance exits when its window closes, so a caller can wait.
      watchCommand = "gnome-text-editor --standalone";
      desktop = "default-editor.desktop";
      icon = "org.gnome.TextEditor";
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
