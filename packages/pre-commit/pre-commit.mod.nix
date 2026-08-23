{inputs, ...}: {
  perSystem = {pkgs, ...}: let
    preCommitCheck = inputs.git-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run {
      src = ../..;
      hooks = {
        alejandra.enable = true;
        check-added-large-files.enable = true;
        check-merge-conflicts.enable = true;
        deadnix.enable = true;
        end-of-file-fixer = {
          enable = true;
          excludes = ["^hosts/.*/report\\.json$"];
        };
        statix.enable = true;
        trim-trailing-whitespace.enable = true;
      };
    };
  in {
    checks.pre-commit = preCommitCheck;

    devShells.default = pkgs.mkShell {
      packages = preCommitCheck.enabledPackages;
      inherit (preCommitCheck) shellHook;
    };
  };
}
