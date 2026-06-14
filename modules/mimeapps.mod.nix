{lib, ...}: {
  flake.nixosModules.mimeapps = {config, ...}: let
    kittyNvimDesktop = ''
      [Desktop Entry]
      Name=Neovim in Kitty
      Comment=Edit files in Neovim inside Kitty
      Exec=kitty -e nvim %F
      Type=Application
      Terminal=false
      Icon=nvim
      Categories=Utility;TextEditor;
      MimeType=text/plain;text/markdown;text/xml;text/x-python;text/x-script.python;text/x-shellscript;application/json;application/toml;application/x-shellscript;
      NoDisplay=true
    '';

    mimeappsList = ''
      [Default Applications]
      application/json=kitty-nvim.desktop
      application/toml=kitty-nvim.desktop
      application/x-shellscript=kitty-nvim.desktop
      application/xhtml+xml=brave-browser.desktop
      inode/directory=thunar.desktop
      text/html=brave-browser.desktop
      text/markdown=kitty-nvim.desktop
      text/plain=kitty-nvim.desktop
      text/x-python=kitty-nvim.desktop
      text/x-script.python=kitty-nvim.desktop
      text/x-shellscript=kitty-nvim.desktop
      text/xml=kitty-nvim.desktop
      x-scheme-handler/chrome=brave-browser.desktop
      x-scheme-handler/http=brave-browser.desktop
      x-scheme-handler/https=brave-browser.desktop
    '';

    hasPreservation =
      lib.hasAttrByPath ["preferences" "preservation" "enable"] config
      && config.preferences.preservation.enable;

    persistentConfigDir = "${toString config.preferences.preservation.persistentStoragePath}/home/${config.userName}/.config";
    persistentAppsDir = "${toString config.preferences.preservation.persistentStoragePath}/home/${config.userName}/.local/share/applications";
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
    desktopTargetFile = "${appsDir}/kitty-nvim.desktop";
  in {
    preferences.preservation.user.files = lib.mkIf hasPreservation [
      ".config/mimeapps.list"
      ".local/share/applications/kitty-nvim.desktop"
    ];

    system.activationScripts.mimeappsList.text = ''
      install -d -m 0755 -o ${config.userName} -g users ${configDir}
      cat > ${mimeappsTargetFile} <<'EOF'
      ${mimeappsList}
      EOF
      chown ${config.userName}:users ${mimeappsTargetFile}
      chmod 0644 ${mimeappsTargetFile}

      install -d -m 0755 -o ${config.userName} -g users ${appsDir}
      cat > ${desktopTargetFile} <<'EOF'
      ${kittyNvimDesktop}
      EOF
      chown ${config.userName}:users ${desktopTargetFile}
      chmod 0644 ${desktopTargetFile}
    '';
  };
}
