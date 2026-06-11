{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.quickshell = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.quickshell;
      runtimeInputs = [pkgs.zoxide];
    };
  };
}
