{lib, ...}: {
  flake.nixosModules.mimeapps = {config, ...}: let
    mimeappsList = ''
      [Default Applications]
      application/json=nvim.desktop
      application/toml=nvim.desktop
      application/x-shellscript=nvim.desktop
      application/xhtml+xml=brave-browser.desktop
      inode/directory=thunar.desktop
      text/html=brave-browser.desktop
      text/markdown=nvim.desktop
      text/plain=nvim.desktop
      text/x-python=nvim.desktop
      text/x-script.python=nvim.desktop
      text/x-shellscript=nvim.desktop
      text/xml=nvim.desktop
      x-scheme-handler/chrome=brave-browser.desktop
      x-scheme-handler/http=brave-browser.desktop
      x-scheme-handler/https=brave-browser.desktop
    '';

    hasPreservation =
      lib.hasAttrByPath ["preferences" "preservation" "enable"] config
      && config.preferences.preservation.enable;

    targetDir =
      if hasPreservation
      then "${toString config.preferences.preservation.persistentStoragePath}/home/${config.userName}/.config"
      else "${config.homeDirectory}/.config";

    targetFile = "${targetDir}/mimeapps.list";
  in {
    preferences.preservation.user.files = lib.mkIf hasPreservation [
      ".config/mimeapps.list"
    ];

    system.activationScripts.mimeappsList.text = ''
      install -d -m 0755 -o ${config.userName} -g users ${targetDir}
      cat > ${targetFile} <<'EOF'
      ${mimeappsList}
      EOF
      chown ${config.userName}:users ${targetFile}
      chmod 0644 ${targetFile}
    '';
  };
}
