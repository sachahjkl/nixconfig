{ ... }:

{
  flake.nixosModules.mimeapps = { config, ... }: {
    hjem.users.${config.userName}.xdg.config.files."mimeapps.list".text = ''
      [Default Applications]
      application/xhtml+xml=brave-browser.desktop
      inode/directory=thunar.desktop
      text/html=brave-browser.desktop
      x-scheme-handler/chrome=brave-browser.desktop
      x-scheme-handler/http=brave-browser.desktop
      x-scheme-handler/https=brave-browser.desktop
    '';
  };
}
