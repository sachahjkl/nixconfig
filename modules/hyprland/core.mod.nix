{ ... }:

{
  flake.nixosModules.hyprlandCore = { lib, pkgs-hyprnix, ... }:
    let
      hyprSessionTarget = "wayland-session@hyprland.desktop.target";
    in
    {
      services.displayManager.ly.enable = true;
      services.displayManager.ly.settings.session_log = null;

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
