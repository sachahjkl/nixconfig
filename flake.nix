{
  description = "Sacha's NixOS system configuration";

  # Flake `nixConfig` must be a literal. Keep these lists in sync with nix-config.nix.
  nixConfig = {
    extra-experimental-features = [
      "flakes"
      "nix-command"
    ];
    extra-substituters = [
      "https://cache.homelab.sacha.house"
      "https://cache.numtide.com"
      "https://nix-community.cachix.org"
      "https://sachahjkl.cachix.org"
      "https://install.determinate.systems"
      "https://cache.manic.systems"
    ];
    extra-trusted-public-keys = [
      "homelab-cache-1:ZaUHSv8slKsAKc9kd0AGI8p1HUjUumfho7ShgUVlnUg="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "sachahjkl.cachix.org-1:cepX7PCUV88hCchnh9prZM5V72wRkCf6oSJL6JfgWs0="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "cache.manic.systems-1:s6OZanN8Us8vRi0jVivP3qlMn0cYHBjBALKrNe5nH8s="
    ];
  };

  # Inputs are tack pins: edit .tack/pins.toml, then run `tack update`.
  outputs = {self, ...} @ args: let
    inputs = (import ./.tack {overrides = args.tackOverrides or {};}) // {inherit self;};
  in
    inputs.flake-parts.lib.mkFlake
    {
      inherit inputs;

      specialArgs.lib = inputs.nixpkgs.lib.extend (
        final: prev:
          inputs.nixpkgs.lib.recursiveUpdate prev (
            import ./lib {
              lib = final;
              inherit inputs;
              inherit (inputs) self;
            }
          )
      );
    }
    (
      {
        config,
        lib,
        ...
      }: let
        inherit (lib.filesystem) listFilesRecursive;
        inherit (lib.lists) filter;
        inherit (lib.strings) hasSuffix;
      in {
        systems = ["x86_64-linux"];

        # flake-parts builds inputs' from self.inputs, which is empty because
        # tack provides the inputs. Build it from the tack inputs.
        perSystem = {system, ...}: {
          _module.args.inputs' = lib.mkForce (
            lib.mapAttrs (_: config.perInput system)
            (lib.filterAttrs (_: input: input._type or null == "flake") inputs)
          );
        };

        imports =
          [
            inputs.disko.flakeModules.default
          ]
          ++ filter (path: hasSuffix ".mod.nix" (toString path)) (listFilesRecursive ./.);
      }
    );
}
