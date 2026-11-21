{inputs, ...}: {
  flake.nixosModules.skills = {
    config,
    lib,
    options,
    ...
  }: let
    cfg = config.ai.skills;
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
    hasUserName = lib.hasAttrByPath ["userName"] options;
    skillEntries = builtins.readDir inputs.skills;
    skillNames = lib.filter (
      name:
        skillEntries.${name}
        == "directory"
        && builtins.pathExists (inputs.skills + "/${name}/SKILL.md")
    ) (builtins.attrNames skillEntries);
    skillRoots = [
      ".agents/skills"
      ".claude/skills"
    ];
    skillFiles = lib.listToAttrs (
      lib.concatMap (
        root:
          map (name: {
            name = "${root}/${name}";
            value.source = inputs.skills + "/${name}";
          })
          skillNames
      )
      skillRoots
    );
  in {
    key = "nixconfig:skills";
    options.ai.skills.enable = lib.mkEnableOption "shared AI skill definitions";

    config = lib.optionalAttrs (hasHjemUsers && hasUserName) {
      hjem.users.${config.userName}.files = lib.mkIf cfg.enable skillFiles;
    };
  };
}
