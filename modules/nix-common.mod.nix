{inputs, ...}: {
  flake.nixosModules.nixCommon = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.useLix = lib.mkOption {
      type = lib.types.enum ["no" "stable" "latest"];
      default = "latest";
      description = "Which Lix package set to use for Nix and related tooling.";
    };

    config = {
      nix = {
        package =
          if config.useLix == "no"
          then pkgs.nix
          else pkgs.lixPackageSets.${config.useLix}.lix;

        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 14d";
        };

        optimise.automatic = true;

        settings =
          (import (inputs.self + /flake.nix)).nixConfig
          // {
            accept-flake-config = true;
            substituters = [
              "https://cache.nixos.org"
              "https://hyprland.cachix.org"
              "https://cache.numtide.com"
              "https://nix-community.cachix.org"
            ];
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
              "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            ];
            trusted-users = ["root" "@wheel"];
          };
      };

      nixpkgs.config.allowUnfree = true;
    };
  };
}
