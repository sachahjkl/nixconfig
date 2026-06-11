{inputs, ...}: {
  flake.lib.mkGit = {pkgs}:
    inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.git;
      runtimeInputs = [pkgs.difftastic pkgs.fzf pkgs.git-lfs pkgs.gnugrep pkgs.mergiraf];
    };
}
