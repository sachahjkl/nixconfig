{ config, lib, pkgs, ... }:

let
  isKDE = lib.elem config.desktop.environment [ "kde" "both" ];
  isHyprland = lib.elem config.desktop.environment [ "hyprland" "both" ];
  sddmTheme = (pkgs.elegant-sddm.override {
    themeConfig.General.background = "${config.sacha.assets.wallpaper}";
  });
in
{
  options.desktop.environment = lib.mkOption {
    type = lib.types.enum [ "kde" "hyprland" "both" ];
    default = "both";
    description = "Desktop environment to enable";
  };

  config = lib.mkMerge [
    {
      services.displayManager.sddm.enable = true;
      services.displayManager.sddm.wayland.enable = true;
      services.displayManager.sddm.wayland.compositor = "kwin";
      services.displayManager.sddm.extraPackages = with pkgs.qt6; [ qt5compat ];
      services.displayManager.sddm.theme = "${sddmTheme}/share/sddm/themes/Elegant";
      services.displayManager.sddm.enableHidpi = true;
      services.displayManager.sddm.settings.General.GreeterEnvironment = "XCURSOR_THEME=${config.sacha.theme.cursor},XCURSOR_SIZE=${toString config.sacha.theme.cursorSize}";
      services.displayManager.sddm.settings.Theme = {
        CursorTheme = config.sacha.theme.cursor;
        CursorSize = config.sacha.theme.cursorSize;
      };
      services.accounts-daemon.enable = true;

      services.xserver.enable = !isHyprland;
      services.xserver.xkb = {
        layout = "fr";
        variant = "";
      };

      programs.firefox.enable = true;
      programs.partition-manager.enable = true;
      security.polkit.enable = true;
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (subject.isInGroup("wheel"))
            return polkit.Result.YES;
        });
      '';
      environment.systemPackages = with pkgs.kdePackages; [ breeze dolphin ];

      qt.enable = true;

      xdg.portal.enable = true;

      services.printing.enable = true;
      services.printing.listenAddresses = [ "localhost:631" ];
      services.printing.defaultShared = false;

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
    }

    (lib.mkIf isKDE {
      services.desktopManager.plasma6.enable = true;
      qt.platformTheme = "kde";
      xdg.portal.extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    })

    (lib.mkIf isHyprland {
      qt.platformTheme = "kde";
      qt.style = "kvantum";
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    })
  ];
}
