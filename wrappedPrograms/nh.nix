{ inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    packages.nh = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = inputs.nh.packages.${pkgs.stdenv.hostPlatform.system}.default;
      env.NH_FLAKE = "/home/sacha/Projects/dotfiles";
    };
  };
}
