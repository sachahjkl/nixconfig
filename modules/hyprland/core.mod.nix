{ ... }:

{
  flake.nixosModules.hyprlandCore =
    { lib, pkgs, ... }:
    let
      hyprSessionTarget = "wayland-session@hyprland.desktop.target";
    in
    {
      services.displayManager.ly.enable = true;
      services.displayManager.ly.settings = {
        session_log = null;
        animate = true;
        animation = "colormix";
        clock = "%c";
        bigclock = true;
        colormix_col1 = "0x00000000";
        colormix_col2 = "0x00FF0100";
        colormix_col3 = "0x00FFAA00";
      };

      services.displayManager.ly.settings.save = true;
      services.displayManager.defaultSession = "hyprland-uwsm";

      programs.hyprland = {
        enable = true;
        withUWSM = true;
        package = pkgs.hyprland;
        portalPackage = pkgs.xdg-desktop-portal-hyprland;
        systemd.setPath.enable = true;
      };

      systemd.user.services.hyprpolkitagent = {
        description = "Hyprland Polkit Authentication Agent";
        wantedBy = [ hyprSessionTarget ];
        partOf = [ hyprSessionTarget ];
        after = [ hyprSessionTarget ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
          Restart = "on-failure";
          RestartSec = 1;
        };
      };

      systemd.user.services.xdg-desktop-portal-hyprland.serviceConfig = {
        Restart = lib.mkForce "no";
      };
    };
}
