{ self, ... }:

{
  flake.nixosModules.niri = { config, lib, pkgs, ... }:
    let
      isNiri = lib.elem config.desktop.environment [ "niri" "both" "all" ];
      selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      config = lib.mkIf isNiri {
        programs.niri = {
          enable = true;
          package = selfPkgs.niri;
        };

        environment.systemPackages = [
          selfPkgs.niri
          selfPkgs.noctalia-shell
          selfPkgs.quickshell
          selfPkgs.terminal
          pkgs.xwayland-satellite
          pkgs.swaybg
          pkgs.grim
          pkgs.slurp
          pkgs.swappy
          pkgs.wl-clipboard
          pkgs.pavucontrol
        ];

        environment.sessionVariables = {
          NIXOS_OZONE_WL = "1";
          QT_QPA_PLATFORM = "wayland";
          TERMINAL = "kitty";
          XCURSOR_SIZE = toString config.sacha.theme.cursorSize;
        };

        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        };
      };
    };
}
