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
      brightnessctl
      dunst
      grim
      hyprpaper
      hypridle
      hyprlock
      hyprpicker
      libsForQt5.qt5ct
      networkmanagerapplet
      playerctl
      qt6.qtwayland
      satty
      smile
      slurp
      udiskie
      waybar
      wireplumber
      wl-clipboard
      wtype
      xdg-user-dirs
      rofiPkg
    ];
  };
}
