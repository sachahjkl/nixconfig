_: {
  flake.nixosModules.mimeapps = {config, ...}: let
    user = config.userName;
    editorExec = "${config.editor.id}-editor";
    editorDesktop = ''
      [Desktop Entry]
      Name=Editor (${config.editor.id})
      Comment=Edit files with the current editor
      TryExec=${editorExec}
      Exec=${editorExec} %F
      Type=Application
      Terminal=false
      Icon=${config.editor.icon}
      Categories=Utility;TextEditor;
      MimeType=text/plain;text/markdown;text/xml;text/x-python;text/x-script.python;text/x-shellscript;application/json;application/toml;application/x-shellscript;
      StartupNotify=true
    '';

    mimeappsList = ''
      [Default Applications]
      application/json=default-editor.desktop
      application/toml=default-editor.desktop
      application/x-shellscript=default-editor.desktop
      application/xhtml+xml=brave-browser.desktop
      inode/directory=thunar.desktop
      text/html=brave-browser.desktop
      text/markdown=default-editor.desktop
      text/plain=default-editor.desktop
      text/x-python=default-editor.desktop
      text/x-script.python=default-editor.desktop
      text/x-shellscript=default-editor.desktop
      text/xml=default-editor.desktop
      x-scheme-handler/chrome=brave-browser.desktop
      x-scheme-handler/http=brave-browser.desktop
      x-scheme-handler/https=brave-browser.desktop
    '';
  in {
    hjem.users.${user} = {
      xdg.config.files."mimeapps.list".text = mimeappsList;
      files.".local/share/applications/default-editor.desktop".text = editorDesktop;
    };

    system.activationScripts.removeLegacyEditorDesktop.text = ''
      rm -f ${config.homeDirectory}/.local/share/applications/kitty-nvim.desktop
      rm -f ${config.homeDirectory}/.local/share/applications/default-editor.desktop~
    '';
  };
}
