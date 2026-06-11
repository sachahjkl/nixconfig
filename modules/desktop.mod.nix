{ self, ... }:

{
  flake.nixosModules.desktop = { pkgs, ... }: {
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
      self.nixosModules.wallpaper
      self.nixosModules.wireplumber
    ];

    features.brave.enable = true;

    services.accounts-daemon.enable = true;

    services.xserver.xkb = {
      layout = "fr";
      variant = "";
    };

    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel"))
          return polkit.Result.YES;
      });
    '';
    environment.systemPackages = with pkgs; [ gparted seahorse ];

    qt = {
      enable = true;
      platformTheme = "qt5ct";
    };

    programs.xfconf.enable = true;
    programs.thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-media-tags-plugin
        thunar-volman
      ];
    };

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };

    services.printing.enable = true;
    services.printing.listenAddresses = [ "localhost:631" ];
    services.printing.defaultShared = false;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    services.blueman.enable = true;
    services.gvfs.enable = true;
    services.tumbler.enable = true;
    services.udisks2.enable = true;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
