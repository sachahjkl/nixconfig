{
  inputs,
  lib,
  moduleLocation,
  ...
}: let
  inherit (lib.attrsets) mapAttrs optionalAttrs;
  inherit (lib.options) mkOption;
  inherit (lib.types) deferredModule lazyAttrsOf;

  wrap = kind: name: value:
    {
      _file = "${toString moduleLocation}#${kind}.${name}";
      imports = [value];
    }
    // optionalAttrs (value ? meta) {
      inherit (value) meta;
    };
in {
  config.flake.nixosModules = {
    disko = inputs.disko.nixosModules.disko;
    external-preservation = inputs.preservation.nixosModules.preservation;
    home-manager = inputs.home-manager.nixosModules.home-manager;
    hjem = inputs.hjem.nixosModules.default;
    mt7927 = inputs.mt7927.nixosModules.default;
    sops = inputs.sops-nix.nixosModules.sops;
  };

  options.flake = {
    lib = mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Library functions exposed by the flake.";
    };

    wrappersModules = mkOption {
      default = {};
      description = "Wrapper modules.";
    };

    commonModules = mkOption {
      type = lazyAttrsOf deferredModule;
      default = {};
      apply = mapAttrs (wrap "commonModules");
      description = "Modules shared between systems.";
    };

    darwinModules = mkOption {
      type = lazyAttrsOf deferredModule;
      default = {};
      apply = mapAttrs (wrap "darwinModules");
      description = "Darwin modules.";
    };

    homeModules = mkOption {
      type = lazyAttrsOf deferredModule;
      default = {};
      apply = mapAttrs (wrap "homeModules");
      description = "Home modules.";
    };

    modularServices = mkOption {
      type = lazyAttrsOf deferredModule;
      default = {};
      apply = mapAttrs (wrap "modularServices");
      description = "Modular service modules.";
    };
  };
}
