{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.herdr = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
  };

  flake.nixosModules.herdr = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.herdr;
    herdrPkg = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
  in {
    options.herdr.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to install herdr CLI.";
    };

    config = lib.mkIf cfg.enable {
      environment.systemPackages = [herdrPkg];
    };
  };
}
