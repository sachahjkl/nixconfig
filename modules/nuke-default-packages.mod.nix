_: {
  flake.nixosModules.nukeDefaultPackages = {
    environment = {
      defaultPackages = [];
      stub-ld.enable = false;
    };
  };
}
