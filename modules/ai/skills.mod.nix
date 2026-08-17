{inputs, ...}: {
  flake.nixosModules.skills = {
    config,
    lib,
    options,
    ...
  }: let
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
    francaisSimple = inputs."francais-simple";
  in {
    config = lib.mkIf hasHjemUsers {
      hjem.users.${config.userName}.files.".agents/skills/francais-simple".source = "${francaisSimple}/skills/francais-simple";
    };
  };
}
