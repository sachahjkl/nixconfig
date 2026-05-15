{ inputs, ... }:

{
  imports = [
    inputs.wrapper-modules.flakeModules.wrappers
  ];

  options.flake = inputs.flake-parts.lib.mkSubmoduleOptions {
    lib = inputs.nixpkgs.lib.mkOption {
      default = { };
    };

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
