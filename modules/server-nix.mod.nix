_: {
  flake.nixosModules.serverNix = {pkgs, ...}: {
    config = {
      environment.systemPackages = [pkgs.colmena];
    };
  };
}
