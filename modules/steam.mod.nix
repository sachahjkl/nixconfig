_: {
  flake.nixosModules.steam = {
    config,
    lib,
    options,
    ...
  }: let
    hasPersistDirs = lib.hasAttrByPath ["persist" "user" "directories"] options;
    steamEnabled = lib.attrByPath ["gaming" "steam" "enable"] false config;
  in {
    config = lib.optionalAttrs hasPersistDirs {
      persist.user.directories = lib.mkIf steamEnabled [".local/share/Steam"];
    };
  };
}
