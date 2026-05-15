{ ... }:

{
  flake.nixosModules.hyprlandPackages = { config, lib, pkgs, self, ... }:
    let
      desktopEnvironment = lib.attrByPath [ "desktop" "environment" ] null config;
      isHypr = lib.elem desktopEnvironment [ "hyprland" "both" "all" ];
      selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
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
        hyprlock
        hyprshot
        hyprpicker
        libsForQt5.qt5ct
        networkmanagerapplet
        papirus-icon-theme
        pasystray
        playerctl
        pwvucontrol
        qt6.qtwayland
        rofi
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
        selfPkgs.terminal
      ];
    };
}
