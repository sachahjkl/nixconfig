_: {
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
  in {
    system.activationScripts.mimeappsList.text = ''
      install -d -m 0755 -o ${config.userName} -g users ${config.homeDirectory}/.config
      cat > ${config.homeDirectory}/.config/mimeapps.list <<'EOF'
      ${mimeappsList}
      EOF
      chown ${config.userName}:users ${config.homeDirectory}/.config/mimeapps.list
      chmod 0644 ${config.homeDirectory}/.config/mimeapps.list
    '';
  };
}
