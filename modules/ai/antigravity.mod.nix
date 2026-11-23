{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.antigravityCli = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.antigravity-cli;
  };

  flake.nixosModules.antigravity = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    cfg = config.ai.antigravity;
    hasPersistDirs = lib.hasAttrByPath ["persist" "user" "directories"] options;
  in {
    options.ai.antigravity.enable = lib.mkEnableOption "Antigravity CLI (agy) and Antigravity App";

    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        environment.systemPackages = [
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.antigravity-cli
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.antigravity-hub
        ];
      }

      # The Google sign-in, the settings and the conversations live in these folders:
      # without them, agy and the App ask for a new sign-in after each boot.
      (lib.optionalAttrs hasPersistDirs {
        persist.user.directories = [
          ".gemini"
          ".antigravity"
          # the Electron profile of the App (its productName is "Antigravity")
          ".config/Antigravity"
        ];
      })
    ]);
  };
}
