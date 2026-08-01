{inputs, ...}: {
  flake.nixosModules.windowsApps = {
    lib,
    options,
    pkgs,
    ...
  }: let
    unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    umuLauncher = pkgs.umu-launcher.override {
      umu-launcher-unwrapped = unstablePkgs.umu-launcher-unwrapped;
    };
  in {
    config = lib.mkMerge [
      {
        environment.systemPackages = with pkgs; [
          bottles
          lutris
          umuLauncher
          wineWow64Packages.stableFull
          winetricks
        ];
      }

      (lib.optionalAttrs (lib.hasAttrByPath ["persist" "user" "directories"] options) {
        persist.user.directories = [
          ".config/bottles"
          ".config/lutris"
          ".local/share/bottles"
          ".local/share/icons"
          ".local/share/lutris"
          ".local/share/umu"
          ".wine"
          "Games"
        ];
      })
    ];
  };
}
