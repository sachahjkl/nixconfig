{ ... }:

{
  flake.nixosModules.hyprlandPackages = { config, pkgs, self, ... }:
    let
      selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
      rofiPkg = self.lib.mkRofi {
        inherit pkgs;
        theme = config.preferences.theme.rofiTheme;
      };
      hyprlockPkg = self.lib.mkHyprlock {
        inherit pkgs;
        wallpaper = config.assets.wallpaper;
        faceIcon = config.assets.faceIcon;
      };
    in
    {
      environment.systemPackages = with pkgs; [
        arc-theme
        brightnessctl
        cliphist
        copyq
        dunst
        grim
        hyprpaper
        hypridle
        hyprshot
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
        hyprlockPkg
        selfPkgs.terminal
      ];
    };
}
