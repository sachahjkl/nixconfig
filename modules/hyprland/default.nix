{ config, pkgs, lib, pkgs-hyprnix, ... }:

let
  isHypr = lib.elem config.desktop.environment [ "hyprland" "both" ];
  hyprSessionTarget = "wayland-session@hyprland.desktop.target";
in
{
  imports = [
    ./packages.nix
    ./config.nix
    ./lock.nix
    ./waybar.nix
    ./dunst.nix
    ./apps.nix
    ./scripts.nix
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
        ExecStart = "${pkgs-hyprnix.hyprpolkitagent}/bin/hyprpolkitagent";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };
  };
}
