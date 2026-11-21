{inputs, ...}: {
  flake.nixosModules.hex = {
    config,
    lib,
    options,
    ...
  }: let
    cfg = config.ai.hex;
    hasHomeManager = lib.hasAttrByPath ["home-manager" "users"] options;
    hasPersistDirs = lib.hasAttrByPath ["persist" "user" "directories"] options;
    hasUserName = lib.hasAttrByPath ["userName"] options;
  in {
    options.ai.hex.enable = lib.mkEnableOption "Hex local voice dictation";

    config = lib.mkIf cfg.enable (lib.mkMerge [
      (lib.optionalAttrs (hasHomeManager && hasUserName) {
        home-manager.users.${config.userName} = {
          imports = [inputs.hex.homeManagerModules.hex];
          programs.hex = {
            enable = true;
            autostart = true;
            installModel = true;
          };
        };
      })

      (lib.optionalAttrs hasPersistDirs {
        persist.user.directories = [
          ".local/share/hex"
        ];
      })
    ]);
  };
}
