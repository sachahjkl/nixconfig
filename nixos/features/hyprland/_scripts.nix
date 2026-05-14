{ config, lib, pkgs, ... }:

let
  isHypr = lib.elem config.desktop.environment [ "hyprland" "both" "all" ];

  rofi-power-menu = pkgs.writeShellApplication {
    name = "rofi-power-menu";
    runtimeInputs = with pkgs; [ systemd uwsm ];
    text = builtins.readFile ./_rofi-power-menu.sh;
  };

  hypr-screenshot = pkgs.writeShellApplication {
    name = "hypr-screenshot";
    runtimeInputs = with pkgs; [ coreutils hyprshot satty uwsm wl-clipboard ];
    text = ''
      set -eu

      mode="''${1:-region}"

      case "$mode" in
        region|window|output)
          ;;
        *)
          printf 'usage: %s [region|window|output]\n' "$0" >&2
          exit 1
          ;;
      esac

      screenshot_dir="''${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
      mkdir -p "$screenshot_dir"

      timestamp="$(date +%Y-%m-%d_%H-%M-%S)"
      output_file="$screenshot_dir/$timestamp.png"

      hyprshot -m "$mode" -o "$screenshot_dir" -f "$timestamp.png"

      exec uwsm app -- satty \
        --filename "$output_file" \
        --output-filename "$output_file" \
        --copy-command wl-copy \
        --actions-on-enter save-to-clipboard,save-to-file,exit \
        --actions-on-right-click save-to-clipboard,save-to-file,exit \
        --floating-hack \
        --no-window-decoration \
        --fullscreen current-screen
    '';
  };
in
lib.mkIf isHypr {
  environment.systemPackages = [
    rofi-power-menu
    hypr-screenshot
  ];
}
