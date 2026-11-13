_: {
  perSystem = {pkgs, ...}: let
    built = import ./package.nix {inherit pkgs;};
  in {
    packages = {
      inherit (built) voxl;
      voxl-xvfb = built.xvfb;
    };
  };
}
