_: {
  flake.nixosModules.hyprlandPackages = {
    config,
    pkgs,
    self,
    ...
  }: let
    rofiPkg = self.lib.mkRofi {
      inherit pkgs;
      theme = config.theme.rofiTheme;
    };
  in {
    environment.systemPackages = with pkgs; [
      arc-theme
      brightnessctl
      cliphist
      copyq
      dunst
      grim
      hyprpaper
      hypridle
      hyprpicker
      libsForQt5.qt5ct
      networkmanagerapplet
      papirus-icon-theme
      pasystray
      playerctl
      pwvucontrol
      qt6.qtwayland
      satty
      slurp
      udiskie
      waybar
      wireplumber
      wl-clipboard
      wtype
      xdg-user-dirs
      inter
      rofiPkg
      hyprlock
    ];
  };
}
