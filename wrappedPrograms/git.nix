{ inputs, ... }:

{
  flake.lib.mkGit =
    { pkgs
    , authorName
    , authorEmail
    }:
    let
      gitConfig = pkgs.writeText "git-config" ''
        [alias]
          oops = commit --amend --no-edit
          pl = push --force-with-lease
          lg = log --graph --oneline
          br = !git switch $(git branch | grep -v "^\\*" | fzf)
          latest = !git switch "$1" && git pull origin $1 #
          echo = !echo - $1 - #
        [column]
          ui = auto
        [branch]
          sort = -committerdate
        [tag]
          sort = version:refname
          gpgSign = true
        [init]
          defaultBranch = master
        [diff]
          algorithm = histogram
          colorMoved = plain
          mnemonicPrefix = true
          renames = true
        [push]
          default = simple
          autoSetupRemote = true
          followTags = true
        [fetch]
          prune = true
          pruneTags = true
          all = true
        [help]
          autocorrect = prompt
        [commit]
          verbose = true
          gpgSign = true
        [rerere]
          autoupdate = true
        [core]
          excludesfile = ~/.gitignore
          fsmonitor = true
          untrackedCache = true
        [rebase]
          autoSquash = true
          autoStash = true
          updateRefs = true
        [pull]
          rebase = true
        [http]
          sslVerify = true
        [merge]
          tool = mergiraf
        [mergetool "mergiraf"]
          cmd = mergiraf --mode=merge3 --base="$BASE" --left="$LOCAL" --right="$REMOTE" --output="$MERGED"
          trustExitCode = true
        [mergetool]
          keepBackup = false
        [user]
          name = ${authorName}
          email = ${authorEmail}
          signingKey = ~/.ssh/id_ed25519_sk.pub
        [gpg]
          format = ssh
        [gpg "ssh"]
          allowedSignersFile = ~/.ssh/allowed_signers
      '';
    in
    inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.git;
      runtimeInputs = [ pkgs.difftastic pkgs.fzf pkgs.git-lfs pkgs.gnugrep pkgs.mergiraf ];
      env = rec {
        GIT_AUTHOR_NAME = authorName;
        GIT_AUTHOR_EMAIL = authorEmail;
        GIT_COMMITTER_NAME = GIT_AUTHOR_NAME;
        GIT_COMMITTER_EMAIL = GIT_AUTHOR_EMAIL;
        GIT_CONFIG_GLOBAL = gitConfig;
      };
    };
}
