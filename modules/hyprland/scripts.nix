{ config, lib, pkgs, ... }:

let
  isHypr = lib.elem config.desktop.environment [ "hyprland" "both" ];

  rofi-power-menu = pkgs.writeShellApplication {
    name = "rofi-power-menu";
    runtimeInputs = with pkgs; [ systemd uwsm ];
    text = builtins.readFile ./rofi-power-menu.sh;
  };
in
lib.mkIf isHypr {
  environment.systemPackages = [ rofi-power-menu ];
}
