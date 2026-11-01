_: {
  flake.nixosModules.windowsApps = {
    lib,
    options,
    pkgs,
    ...
  }: {
    config = lib.mkMerge [
      {
        environment.systemPackages = with pkgs; [
          bottles
          lutris
          umu-launcher
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
