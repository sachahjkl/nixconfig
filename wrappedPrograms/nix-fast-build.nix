{ inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    packages.nix-fast-build = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = inputs.nix-fast-build.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
  };
}
