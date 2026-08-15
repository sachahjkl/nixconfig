{inputs, ...}: {
  flake.nixosModules.windowsApps = {
    lib,
    options,
    pkgs,
    ...
  }: let
    mv = inputs.multiverse.multiverse.${pkgs.stdenv.hostPlatform.system};
    inherit (mv.tip) umu-launcher-unwrapped;
    umuLauncher = pkgs.umu-launcher.override {
      inherit umu-launcher-unwrapped;
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
