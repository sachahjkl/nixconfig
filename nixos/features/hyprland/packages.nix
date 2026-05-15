{ ... }:

{
  flake.nixosModules.hyprlandPackages = { config, lib, pkgs, self, ... }:
    let
      desktopEnvironment = lib.attrByPath [ "desktop" "environment" ] null config;
      isHypr = lib.elem desktopEnvironment [ "hyprland" "both" "all" ];
      selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
      rofiPkg = self.lib.mkRofi {
        inherit pkgs;
        theme = config.sacha.theme.rofiTheme;
      };
      hyprlockPkg = self.lib.mkHyprlock {
        inherit pkgs;
        wallpaper = config.sacha.assets.wallpaper;
        faceIcon = config.sacha.assets.faceIcon;
      };
    in
    lib.mkIf isHypr {
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
        posy-cursors
        rofiPkg
        hyprlockPkg
        selfPkgs.terminal
      ];
    };
}
