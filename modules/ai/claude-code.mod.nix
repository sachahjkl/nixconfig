{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.claudeCode = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
  };

  flake.nixosModules.claudeCode = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.ai.claudeCode;
  in {
    options.ai.claudeCode.enable = lib.mkEnableOption "Claude Code CLI";

    config = lib.mkIf cfg.enable {
      environment.systemPackages = [
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
      ];

      persist.user.directories = [
        ".claude"
      ];

      persist.user.files = [
        ".claude.json"
      ];
    };
  };
}
