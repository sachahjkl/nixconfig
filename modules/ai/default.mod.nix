{self, ...}: {
  flake.nixosModules.ai = {
    config,
    lib,
    ...
  }: let
    cfg = config.ai;
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

    config = {
      ai.handy.enable = lib.mkDefault cfg.enable;
      ai.omp.enable = lib.mkDefault cfg.enable;
      codex.enable = lib.mkDefault (cfg.enable && cfg.codex.enable);
      herdr.enable = lib.mkDefault (cfg.enable && cfg.herdr.enable);
    };
  };
}
