_: {
  flake.nixosModules.kdeCore = {
    config,
    lib,
    pkgs,
    ...
  }: let
    kdeUiFont = "${config.preferences.theme.fonts.sans} Medium,10,-1,5,500,0,0,0,0,0,0,0,0,0,0,1,Regular,0,0";
    kdeMenuFont = "${config.preferences.theme.fonts.sans},10,-1,5,500,0,0,0,0,0,0,0,0,0,0,1,Medium,0,0";
    kdeSmallFont = "${config.preferences.theme.fonts.sans},8,-1,5,500,0,0,0,0,0,0,0,0,0,0,1,Medium,0,0";
    kdeMonoFont = "${config.preferences.theme.fonts.mono},10,-1,5,500,0,0,0,0,0,0,0,0,0,0,1,Medium,0,0";
    wallpaperUri = "file://${toString config.assets.wallpaper}";
    wallpaperScript = pkgs.writeShellScript "plasma-apply-shared-wallpaper" ''
      ${lib.getExe' pkgs.systemd "busctl"} --user call \
        org.kde.plasmashell \
        /PlasmaShell \
        org.kde.PlasmaShell \
        evaluateScript \
        s \
        'var desktops = desktops(); for (var i = 0; i < desktops.length; ++i) { var desktop = desktops[i]; desktop.wallpaperPlugin = "org.kde.image"; desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"]; desktop.writeConfig("Image", "${wallpaperUri}"); }' >/dev/null
    '';
  in {
    services = {
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };

      desktopManager.plasma6.enable = true;
    };

    environment.systemPackages = with pkgs.kdePackages; [
      ark
      dolphin
      elisa
      ffmpegthumbs
      gwenview
      kalk
      kamoso
      kate
      kcalc
      kcolorchooser
      kdenlive
      kdialog
      kio-admin
      kio-extras
      krdp
      okular
      plasma-browser-integration
      spectacle
    ];
    home-manager.users.${config.userName}.programs.plasma = {
      enable = true;
      configFile = {
        baloofilerc."Basic Settings"."Indexing-Enabled" = false;

        kickerrc = {
          General.showAppsByName = true;
          ActionPlugin = {
            recentApplications = false;
            recentDocuments = false;
            systemApplications = false;
          };
        };

        kdeglobals = {
          General = {
            TerminalApplication = "kitty";
            XftHintStyle = "hintfull";
            XftSubPixel = "rgb";
            fixed = kdeMonoFont;
            font = kdeUiFont;
            menuFont = kdeMenuFont;
            smallestReadableFont = kdeSmallFont;
            toolBarFont = kdeMenuFont;
          };
          Icons.Theme = "breeze";
          KDE = {
            AnimationDurationFactor = 0;
            AutomaticLookAndFeel = true;
            DefaultDarkLookAndFeel = "org.kde.breezedark.desktop";
            DefaultLightLookAndFeel = "org.kde.breeze.desktop";
            widgetStyle = "Breeze";
          };
          WM.activeFont = kdeMenuFont;
        };

        konsolerc."Desktop Entry".DefaultProfile = "Custom.profile";

        kcminputrc = {
          Keyboard = {
            RepeatDelay = 200;
            RepeatRate = 60;
          };
          Mouse = {
            cursorSize = 48;
            cursorTheme = "Posy_Cursor_Black";
          };
        };

        kwinrc."org.kde.kdecoration2" = {
          library = "org.kde.kwin.aurorae";
          theme = "kwin4_decoration_qml_plastik";
        };

        plasmarc.Wallpapers.usersWallpapers = toString config.assets.wallpaper;

        plasma-localerc.GeoLocation = {
          Latitude = "46.8";
          Longitude = "1.183";
        };
      };
    };

    systemd.user.services.plasma-wallpaper = {
      description = "Apply shared Plasma wallpaper";
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target" "plasma-plasmashell.service"];
      wantedBy = ["graphical-session.target"];

      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${lib.getExe' pkgs.coreutils "sleep"} 2";
        ExecStart = wallpaperScript;
      };
    };

    preferences.preservation.user = {
      directories = [
        ".local/share/konsole"
      ];

      files = [
        ".config/kactivitymanagerdrc"
        ".config/kactivitymanagerd-statsrc"
        ".config/kglobalshortcutsrc"
        ".config/khotkeysrc"
        ".config/konsolerc"
        ".config/kwinoutputconfig.json"
        ".config/plasma-org.kde.plasma.desktop-appletsrc"
        ".config/plasmashellrc"
      ];
    };
  };
}
