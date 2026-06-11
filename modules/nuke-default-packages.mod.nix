_: {
  flake.nixosModules.nukeDefaultPackages = {
    environment.defaultPackages = [];
    environment.stub-ld.enable = false;
  };
}
