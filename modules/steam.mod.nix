_: {
  flake.nixosModules.steam = {
    config,
    lib,
    ...
  }: let
    steamEnabled = lib.attrByPath ["gaming" "steam" "enable"] false config;
  in {
    config = lib.mkIf steamEnabled {
      persist.user.directories = [".local/share/Steam"];
    };
  };
}
