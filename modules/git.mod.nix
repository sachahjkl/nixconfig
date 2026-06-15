_: {
  flake.nixosModules.git = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    cfg = config.preferences.git;
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
  in {
    options.preferences.git = {
      authorName = lib.mkOption {
        type = lib.types.str;
        default = "sachahjkl";
        description = "Default Git author name.";
      };

      authorEmail = lib.mkOption {
        type = lib.types.str;
        default = "sacha@sacha.house";
        description = "Default Git author email.";
      };

      signingKey = lib.mkOption {
        type = lib.types.str;
        default = "~/.ssh/id_ed25519_sk.pub";
        description = "SSH public key path used for Git commit signing.";
      };
    };

    config = lib.mkMerge [
      {
        preferences.preservation.user.directories = [
          ".config/gitui"
        ];

        environment.systemPackages = with pkgs; [
          difftastic
          fzf
          git
          git-lfs
          gitui
          mergiraf
        ];
      }

      (lib.optionalAttrs hasHjemUsers {
        hjem.users.${config.userName}.rum.programs.git = {
          enable = true;
          package = null;
          settings = {
            alias = {
              oops = "commit --amend --no-edit";
              pl = "push --force-with-lease";
              lg = "log --graph --oneline";
              br = "!git switch $(git branch | grep -v \"^\\*\" | fzf)";
              latest = "!git switch \"$1\" && git pull origin $1 #";
              echo = "!echo - $1 - #";
            };
            column.ui = "auto";
            branch.sort = "-committerdate";
            tag = {
              sort = "version:refname";
              gpgSign = true;
            };
            init.defaultBranch = "master";
            diff = {
              algorithm = "histogram";
              colorMoved = "plain";
              mnemonicPrefix = true;
              renames = true;
            };
            push = {
              default = "simple";
              autoSetupRemote = true;
              followTags = true;
            };
            fetch = {
              prune = true;
              pruneTags = true;
              all = true;
            };
            help.autocorrect = "prompt";
            commit = {
              verbose = true;
              gpgSign = true;
            };
            rerere.autoupdate = true;
            core = {
              excludesfile = "~/.gitignore";
              fsmonitor = true;
              untrackedCache = true;
            };
            rebase = {
              autoSquash = true;
              autoStash = true;
              updateRefs = true;
            };
            pull.rebase = true;
            http.sslVerify = true;
            merge.tool = "mergiraf";
            mergetool.keepBackup = false;
            "mergetool \"mergiraf\"" = {
              cmd = "mergiraf --mode=merge3 --base=\"$BASE\" --left=\"$LOCAL\" --right=\"$REMOTE\" --output=\"$MERGED\"";
              trustExitCode = true;
            };
            gpg.format = "ssh";
            "gpg \"ssh\"".allowedSignersFile = "~/.ssh/allowed_signers";
            user = {
              name = cfg.authorName;
              email = cfg.authorEmail;
              inherit (cfg) signingKey;
            };
          };
        };
      })
    ];
  };
}
