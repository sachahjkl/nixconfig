{self, ...}: {
  flake.nixosModules.ai = {
    config,
    lib,
    options,
    ...
  }: let
    cfg = config.ai;
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
    hasUserName = lib.hasAttrByPath ["userName"] options;
    instructions = builtins.path {
      path = self + /modules/ai/instructions.md;
      name = "ai-instructions.md";
    };
  in {
    imports = [
      self.nixosModules.antigravity
      self.nixosModules.claudeCode
      self.nixosModules.codex
      self.nixosModules.hex
      self.nixosModules.herdr
      self.nixosModules.omp
      self.nixosModules.skills
    ];

    options.ai = {
      enable = lib.mkEnableOption "AI features";
      codex.enable = lib.mkEnableOption "Codex CLI";
      herdr.enable = lib.mkEnableOption "herdr CLI";
    };

    config = lib.mkMerge [
      {
        ai = {
          antigravity.enable = lib.mkDefault cfg.enable;
          claudeCode.enable = lib.mkDefault cfg.enable;
          hex.enable = lib.mkDefault cfg.enable;
          omp.enable = lib.mkDefault cfg.enable;
          skills.enable = lib.mkDefault cfg.enable;
        };
        codex.enable = lib.mkDefault (cfg.enable && cfg.codex.enable);
        herdr.enable = lib.mkDefault (cfg.enable && cfg.herdr.enable);
      }

      (lib.optionalAttrs (hasHjemUsers && hasUserName) {
        hjem.users.${config.userName}.files = lib.mkIf cfg.enable (
          lib.optionalAttrs cfg.claudeCode.enable {
            ".claude/CLAUDE.md".source = instructions;
          }
          // lib.optionalAttrs cfg.antigravity.enable {
            ".gemini/GEMINI.md".source = instructions;
          }
          // lib.optionalAttrs config.codex.enable {
            ".config/codex/AGENTS.md".source = instructions;
          }
        );
      })
    ];
  };
}
