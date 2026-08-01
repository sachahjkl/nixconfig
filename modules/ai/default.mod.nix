{self, ...}: {
  flake.nixosModules.ai = {
    config,
    lib,
    options,
    ...
  }: let
    cfg = config.ai;
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
  in {
    imports = [
      self.nixosModules.codex
      self.nixosModules.handy
      self.nixosModules.herdr
      self.nixosModules.omp
    ];

    options.ai = {
      enable = lib.mkEnableOption "AI features";
      codex.enable = lib.mkEnableOption "Codex CLI";
      herdr.enable = lib.mkEnableOption "herdr CLI";
    };

    config = lib.mkMerge [
      {
        ai.handy.enable = lib.mkDefault cfg.enable;
        ai.omp.enable = lib.mkDefault cfg.enable;
        codex.enable = lib.mkDefault (cfg.enable && cfg.codex.enable);
        herdr.enable = lib.mkDefault (cfg.enable && cfg.herdr.enable);
      }

      (lib.mkIf (cfg.enable && hasHjemUsers) {
        hjem.users.${config.userName}.files = {
          ".claude/CLAUDE.md".source = self + /modules/ai/instructions.md;
          ".config/codex/AGENTS.md".source = self + /modules/ai/instructions.md;
          ".gemini/GEMINI.md".source = self + /modules/ai/instructions.md;
        };
      })
    ];
  };
}
