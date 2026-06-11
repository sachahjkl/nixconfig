_: {
  flake.nixosModules.mimeapps = {config, ...}: {
    hjem.users.${config.userName}.xdg.mime-apps.default-applications = {
      "application/xhtml+xml" = "brave-browser.desktop";
      "inode/directory" = "thunar.desktop";
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/chrome" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
    };
  };
}
