{ inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    packages.git = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.git;
      runtimeInputs = [ pkgs.git-lfs pkgs.difftastic ];
      env = rec {
        GIT_AUTHOR_NAME = "sachahjkl";
        GIT_AUTHOR_EMAIL = "sacha@sacha.house";
        GIT_COMMITTER_NAME = GIT_AUTHOR_NAME;
        GIT_COMMITTER_EMAIL = GIT_AUTHOR_EMAIL;
      };
    };
  };
}
