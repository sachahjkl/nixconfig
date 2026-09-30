_: {
  perSystem = {pkgs, ...}: let
    screenshot = import ./package.nix {inherit pkgs;};
  in {
    packages.hyprland-screenshot = screenshot;
    checks.hyprland-screenshot = screenshot;
  };
}
