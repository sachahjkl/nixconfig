{ ... }:

{
  flake.nixosModules.hyprlandScripts = { pkgs, ... }: {
    environment.systemPackages =
      let
        rofi-power-menu = pkgs.writeShellApplication {
          name = "rofi-power-menu";
          runtimeInputs = with pkgs; [ systemd uwsm ];
          text = builtins.readFile ./rofi-power-menu.sh;
        };

      in
      [
        rofi-power-menu
      ];
  };
}
