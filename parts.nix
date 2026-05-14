{ inputs, ... }:

{
  imports = [
    inputs.wrapper-modules.flakeModules.wrappers
  ];

  options.flake = inputs.flake-parts.lib.mkSubmoduleOptions {
    wrappersModules = inputs.nixpkgs.lib.mkOption {
      default = { };
    };

    diskoConfigurations = inputs.nixpkgs.lib.mkOption {
      default = { };
    };
  };

  config.systems = [
    "x86_64-linux"
  ];
}
