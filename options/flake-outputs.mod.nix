{
  inputs,
  lib,
  moduleLocation,
  ...
}: let
  inherit (lib.attrsets) mapAttrs optionalAttrs;
  inherit (lib.fixedPoints) fix;
  inherit (lib.options) mkOption;
  inherit (lib.types) deferredModule lazyAttrsOf;

  wrap = {
    kind,
    class ? null,
  }: name: value:
    fix (module:
      {
        _file = "${toString moduleLocation}#${kind}.${name}";
        key = module._file;
        imports = [value];
      }
      // optionalAttrs (class != null) {
        _class = class;
      }
      // optionalAttrs (value ? meta) {
        inherit (value) meta;
      });
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
      apply = mapAttrs (wrap {kind = "commonModules";});
      description = "Modules shared between systems.";
    };

    darwinModules = mkOption {
      type = lazyAttrsOf deferredModule;
      default = {};
      apply = mapAttrs (wrap {
        kind = "darwinModules";
        class = "darwin";
      });
      description = "Darwin modules.";
    };

    homeModules = mkOption {
      type = lazyAttrsOf deferredModule;
      default = {};
      apply = mapAttrs (wrap {
        kind = "homeModules";
        class = "hjem";
      });
      description = "Home modules.";
    };

    serviceModules = mkOption {
      type = lazyAttrsOf deferredModule;
      default = {};
      apply = mapAttrs (wrap {
        kind = "serviceModules";
        class = "service";
      });
      description = "Service modules.";
    };
  };
}
