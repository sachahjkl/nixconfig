_: {
  flake.nixosModules.chromium = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.apps.chromium.enable = lib.mkEnableOption "Chromium browser";

    config = lib.mkIf config.apps.chromium.enable {
      environment.systemPackages = [
        (pkgs.chromium.override {
          # Keep Chromium's encrypted profile data on one secrets backend
          # across sessions so cookies and logins survive the KDE -> Hyprland
          # switch and future reboots.
          commandLineArgs = lib.concatStringsSep " " [
            "--password-store=gnome-libsecret"
            "--ozone-platform-hint=auto"
            "--enable-features=WaylandWindowDecorations"
          ];
        })
      ];

      programs.chromium = {
        enable = true;
        # Chromium dropped Manifest V2. uBlock Origin Lite is the Manifest V3 build.
        extensions = [
          "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
          "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
          "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
          "edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies
          "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
        ];
        defaultSearchProviderEnabled = true;
        defaultSearchProviderSearchURL = "https://search.brave.com/search?q={searchTerms}";
        defaultSearchProviderSuggestURL = "https://search.brave.com/api/suggest?q={searchTerms}";
        extraOpts = {
          BlockThirdPartyCookies = true;
          BrowserSignin = 0;
          # Bitwarden stores the passwords.
          PasswordManagerEnabled = false;
          MetricsReportingEnabled = false;
          SafeBrowsingProtectionLevel = 1;
          SyncDisabled = true;
          UrlKeyedAnonymizedDataCollectionEnabled = false;
          # Restore the previous tabs on start.
          RestoreOnStartup = 1;
          PromotionalTabsEnabled = false;
          ShoppingListEnabled = false;
        };
      };

      persist.user.directories = [".config/chromium"];
    };
  };
}
