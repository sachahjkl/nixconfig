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

      # Written here, not through programs.chromium: that module writes the
      # same policies for Brave and Chrome. These are Chromium's only.
      environment.etc."chromium/policies/managed/policy.json".text = builtins.toJSON {
        # Chromium dropped Manifest V2. uBlock Origin Lite is the Manifest V3 build.
        ExtensionInstallForcelist = [
          "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
          "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
          "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
          "edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies
        ];
        DefaultSearchProviderEnabled = true;
        DefaultSearchProviderSearchURL = "https://www.google.com/search?q={searchTerms}";
        DefaultSearchProviderSuggestURL = "https://www.google.com/complete/search?client=chrome&q={searchTerms}";
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

      persist.user.directories = [".config/chromium"];
    };
  };
}
