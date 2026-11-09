_: {
  perSystem = {pkgs, ...}: let
    screenshot = import ./package.nix {inherit pkgs;};
  in {
    packages.screenshot = screenshot;
    checks.screenshot = screenshot;
  };
}
