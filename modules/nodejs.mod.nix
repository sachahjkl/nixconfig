_: {
  flake.nixosModules.nodejs = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
    hasHomeDirectory = lib.hasAttrByPath ["homeDirectory"] options;
    hasUserName = lib.hasAttrByPath ["userName"] options;
  in {
    config = lib.mkMerge [
      {
        environment.systemPackages = [pkgs.nodejs];
      }

      (lib.optionalAttrs (hasHjemUsers && hasHomeDirectory && hasUserName) {
        hjem.users.${config.userName}.files.".npmrc".text = ''
          prefix=${config.homeDirectory}/.local
        '';
      })
    ];
  };
}
