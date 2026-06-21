{lib, ...}: {
  flake.nixosModules.mimeapps = {config, ...}: let
    editorDesktop = ''
      [Desktop Entry]
      Name=Default Editor
      Comment=Edit files with the current editor
      Exec=${config.editor.launchCommandWithFile} %F
      Type=Application
      Terminal=false
      Icon=${config.editor.icon}
      Categories=Utility;TextEditor;
      MimeType=text/plain;text/markdown;text/xml;text/x-python;text/x-script.python;text/x-shellscript;application/json;application/toml;application/x-shellscript;
      NoDisplay=true
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

    hasPreservation =
      lib.hasAttrByPath ["persist" "enable"] config
      && config.persist.enable;

    persistentConfigDir = "${toString config.persist.persistentStoragePath}/home/${config.userName}/.config";
    persistentAppsDir = "${toString config.persist.persistentStoragePath}/home/${config.userName}/.local/share/applications";
    homeConfigDir = "${config.homeDirectory}/.config";
    homeAppsDir = "${config.homeDirectory}/.local/share/applications";

    configDir =
      if hasPreservation
      then persistentConfigDir
      else homeConfigDir;
    appsDir =
      if hasPreservation
      then persistentAppsDir
      else homeAppsDir;

    mimeappsTargetFile = "${configDir}/mimeapps.list";
    desktopTargetFile = "${appsDir}/default-editor.desktop";
  in {
    system.activationScripts.mimeappsList.text = ''
      install -d -m 0755 -o ${config.userName} -g users ${configDir}
      cat > ${mimeappsTargetFile} <<'EOF'
      ${mimeappsList}
      EOF
      chown ${config.userName}:users ${mimeappsTargetFile}
      chmod 0644 ${mimeappsTargetFile}

      install -d -m 0755 -o ${config.userName} -g users ${appsDir}
      cat > ${desktopTargetFile} <<'EOF'
      ${editorDesktop}
      EOF
      chown ${config.userName}:users ${desktopTargetFile}
      chmod 0644 ${desktopTargetFile}
    '';
  };
}
