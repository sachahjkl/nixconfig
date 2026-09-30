{pkgs}:
pkgs.writeShellApplication {
  name = "hyprland-screenshot";
  runtimeInputs = with pkgs; [coreutils gawk grim hyprland hyprpicker jq satty slurp wl-clipboard];
  text = builtins.readFile ./screenshot.sh;
}
