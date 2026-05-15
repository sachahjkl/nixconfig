{ inputs
, lib
, ...
}:

{
  perSystem = { pkgs, ... }: {
    packages.lf = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.lf;
    };
  };
}
