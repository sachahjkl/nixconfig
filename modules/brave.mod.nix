_: {
  flake.nixosModules.brave = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.apps.brave.enable = lib.mkEnableOption "Brave browser";

    config = lib.mkIf config.apps.brave.enable {
      environment.systemPackages = [
        (pkgs.brave.override {
          # Keep Chromium's encrypted profile data on one secrets backend
          # across sessions so cookies and logins survive the KDE -> Hyprland
          # switch and future reboots.
          commandLineArgs = "--password-store=gnome-libsecret";
        })
      ];
      # The default browser.
      xdg.mime.defaultApplications = lib.genAttrs [
        "application/xhtml+xml"
        "text/html"
        "x-scheme-handler/chrome"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ] (_: "brave-browser.desktop");

      persist.user.directories = [".config/BraveSoftware"];
    };
  };
}
