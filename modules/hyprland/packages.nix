{ config, lib, pkgs, ... }:

let
  isHypr = lib.elem config.desktop.environment [ "hyprland" "both" ];
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
    kitty
    kdePackages.kservice
    libsForQt5.qt5ct
    networkmanagerapplet
    papirus-icon-theme
    playerctl
    pwvucontrol
    qt6.qtwayland
    rofi
    slurp
    udiskie
    waybar
    wireplumber
    wl-clipboard
    wtype
    xdg-user-dirs
    inter
    posy-cursors
  ];
}
