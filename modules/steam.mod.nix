_: {
  flake.nixosModules.steam = {
    config,
    lib,
    ...
  }: {
    options.features.steam.enable = lib.mkEnableOption "Steam";

    config = lib.mkIf config.features.steam.enable {
      preferences.preservation.user.directories = [".local/share/Steam"];
    };
  };
}
