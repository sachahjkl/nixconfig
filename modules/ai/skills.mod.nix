{inputs, ...}: {
  flake.nixosModules.skills = {
    config,
    lib,
    options,
    ...
  }: let
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
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
      ".gemini/skills"
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
    config = lib.mkIf hasHjemUsers {
      hjem.users.${config.userName}.files = skillFiles;
    };
  };
}
