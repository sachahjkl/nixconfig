{ config, pkgs, lib, pkgs-hyprnix, ... }:

let
  isHypr = lib.elem config.desktop.environment [ "hyprland" "both" "all" ];
  hyprSessionTarget = "wayland-session@hyprland.desktop.target";
in
{
  imports = [
    ./_packages.nix
    ./_config.nix
    ./_lock.nix
    ./_waybar.nix
    ./_dunst.nix
    ./_apps.nix
    ./_scripts.nix
  ];

  config = lib.mkIf isHypr {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      package = pkgs-hyprnix.hyprland;
      portalPackage = pkgs-hyprnix.xdg-desktop-portal-hyprland;
      systemd.setPath.enable = true;
    };

    systemd.user.services.hyprpolkitagent = {
      description = "Hyprland Polkit Authentication Agent";
      wantedBy = [ hyprSessionTarget ];
      partOf = [ hyprSessionTarget ];
      after = [ hyprSessionTarget ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs-hyprnix.hyprpolkitagent}/libexec/hyprpolkitagent";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };

    systemd.user.services.xdg-desktop-portal-hyprland.serviceConfig = {
      Restart = lib.mkForce "no";
    };
  };
}
