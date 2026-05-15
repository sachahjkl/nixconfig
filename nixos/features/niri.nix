{ inputs, self, ... }:

{
  flake.nixosModules.niri = { config, lib, pkgs, ... }:
    let
      selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
      terminalPkg = self.lib.mkTerminal {
        inherit pkgs;
        shell = lib.getExe selfPkgs.userShell;
        useThemeColors = config.preferences.kitty.useThemeColors;
      };
      niriPkg = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        imports = [ self.wrappersModules.niri ];
        terminal = lib.getExe terminalPkg;
      };
    in
    {
      programs.niri = {
        enable = true;
        package = niriPkg;
      };

      environment.systemPackages = [
        niriPkg
        selfPkgs.noctalia-shell
        selfPkgs.quickshell
        terminalPkg
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
        XCURSOR_SIZE = toString config.preferences.theme.cursorSize;
      };

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };
    };
}
