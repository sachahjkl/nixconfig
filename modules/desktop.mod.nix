{self, ...}: {
  flake.nixosModules.desktop = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [
      self.nixosModules.brave
      self.nixosModules.face-icon
      self.nixosModules.firefox
      self.nixosModules.flatpak
      self.nixosModules.fonts
      self.nixosModules.kitty
      self.nixosModules.mimeapps
      self.nixosModules.obsStudio
      self.nixosModules.theming
      self.nixosModules.thunar
      self.nixosModules.wallpaper
      self.nixosModules.wireplumber
    ];

    features.brave.enable = true;

    security = {
      polkit = {
        enable = true;
        extraConfig = ''
          polkit.addRule(function(action, subject) {
            if (subject.isInGroup("wheel"))
              return polkit.Result.YES;
          });
        '';
      };
      rtkit.enable = true;
    };

    services = {
      accounts-daemon.enable = true;
      xserver.xkb = {
        layout = "fr";
        variant = "";
      };
      printing = {
        enable = true;
        listenAddresses = ["localhost:631"];
        defaultShared = false;
      };
      blueman.enable = true;
      gvfs.enable = true;
      tumbler.enable = true;
      udisks2.enable = true;
      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
      pulseaudio.enable = false;
      pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;
      };
    };

    environment = {
      sessionVariables.TERMINAL = lib.mkDefault config.preferences.terminal.emulatorName;
    };

    qt = {
      enable = true;
      platformTheme = "qt5ct";
    };

    xdg = {
      terminal-exec.settings = {
        enable = true;
        default = lib.mkDefault [config.preferences.terminal.desktop];
      };
      portal = {
        enable = true;
        extraPortals = [pkgs.xdg-desktop-portal-gtk];
        config.common = {
          default = ["gtk"];
          "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
        };
      };
    };

    programs = {
      xfconf.enable = true;
      thunar = {
        enable = true;
        plugins = with pkgs; [
          thunar-archive-plugin
          thunar-media-tags-plugin
          thunar-volman
        ];
      };
    };

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
