{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.codex = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
  };

  flake.nixosModules.codex = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.codex;
    inherit (lib) mkIf mkOption types;
  in {
    options.codex = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to install and configure Codex CLI.";
      };
    };

    config = mkIf cfg.enable (let
      upstreamCodex = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;

      wrappedCodex = pkgs.writeShellScriptBin "codex" ''
        exec ${lib.getExe upstreamCodex} "$@"
      '';

      codexCompletions =
        pkgs.runCommand "codex-completions" {
          nativeBuildInputs = [wrappedCodex];
        } ''
          mkdir -p "$out/share/fish/vendor_completions.d"
          mkdir -p "$out/share/bash-completion/completions"
          mkdir -p "$out/share/zsh/site-functions"
          HOME=$TMPDIR codex completion fish > "$out/share/fish/vendor_completions.d/codex.fish"
          HOME=$TMPDIR codex completion bash > "$out/share/bash-completion/completions/codex"
          HOME=$TMPDIR codex completion zsh > "$out/share/zsh/site-functions/_codex"
        '';
    in {
      hjem.users.${config.userName}.environment.sessionVariables.CODEX_HOME = "${config.homeDirectory}/.config/codex";

      environment.systemPackages = [
        wrappedCodex
        codexCompletions
      ];

      persist.user.directories = [
        ".config/codex"
      ];
    });
  };
}
