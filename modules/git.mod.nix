{self, ...}: {
  flake.nixosModules.git = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    cfg = config.git;
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
    isDark = lib.attrByPath ["theme" "isDark"] true config;
    cornerRadius = lib.attrByPath ["theme" "cornerRadius"] 0 config;
    difft = pkgs.writeShellScriptBin "difft" ''
      exec ${lib.getExe pkgs.difftastic} --background ${
        if isDark
        then "dark"
        else "light"
      } "$@"
    '';
    jjOpen = pkgs.writers.writeNuBin "jj-open" (builtins.readFile ./jujutsu/jj-open.nu);
    jjFork = pkgs.writers.writeNuBin "jj-fork" (builtins.readFile ./jujutsu/jj-fork.nu);
    jjConfig = pkgs.writers.writeTOML "jj-config.toml" {
      user = {
        name = cfg.authorName;
        email = cfg.authorEmail;
      };

      aliases = {
        ".." = ["edit" "@-"];
        ",," = ["edit" "@+"];
        f = ["git" "fetch"];
        p = ["git" "push"];
        cl = ["git" "clone"];
        i = ["git" "init"];
        a = ["abandon"];
        c = ["commit"];
        ci = ["commit" "--interactive"];
        d = ["diff"];
        e = ["edit"];
        l = ["log"];
        la = ["log" "--revisions" "::"];
        r = ["rebase"];
        res = ["resolve"];
        resa = ["resolve-ast"];
        resolve-ast = ["resolve" "--tool" "mergiraf"];
        s = ["squash"];
        si = ["squash" "--interactive"];
        sh = ["show"];
        u = ["undo"];
        open = ["util" "exec" "--" (lib.getExe jjOpen)];
        fork = ["util" "exec" "--" (lib.getExe jjFork)];
      };

      revsets = {
        bookmark-advance-from = ''
          coalesce(
            heads(::to & bookmarks() & ~immutable()),
            heads(::to & bookmarks()),
          )
        '';
        bookmark-advance-to = ''
          heads(::@ & mutable() & ~description(exact:"") & (~empty() | merges()))
        '';
        log = ''
          present(@) | present(trunk()) | ancestors(remote_bookmarks().. | @.., 8)
        '';
      };

      ui = {
        default-command = "log";
        diff-editor = ":builtin";
        diff-formatter = [(lib.getExe difft) "--color" "always" "$left" "$right"];
        conflict-marker-style = "snapshot";
        graph.style =
          if cornerRadius > 0
          then "curved"
          else "square";
      };

      templates = {
        log = "builtin_log_compact";
        draft_commit_description = ''
          concat(
            coalesce(description, "\n"),
            surround(
              "\nJJ: This commit contains the following changes:\n", "",
              indent("JJ:     ", diff.stat(72)),
            ),
            "\nJJ: ignore-rest\n",
            diff.git(),
          )
        '';
        git_push_bookmark = ''"${cfg.forgeUser}/change-" ++ change_id.short()'';
      };

      remotes."*" = {
        auto-track-bookmarks = "${cfg.forgeUser}/*";
        push-new-bookmarks = true;
      };

      git = {
        fetch = ["origin"];
        push = "origin";
        sign-on-push = true;
      };

      signing = {
        backend = "ssh";
        backends.ssh.allowed-signers = "~/.ssh/allowed_signers";
        behavior = "drop";
        key = cfg.signingKey;
      };

      merge-tools.mergiraf.program = lib.getExe pkgs.mergiraf;

      fsmonitor = {
        backend = "watchman";
        watchman.register-snapshot-trigger = true;
      };
    };
  in {
    options.git = {
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

      forgeUser = lib.mkOption {
        type = lib.types.str;
        default = "sachahjkl";
        description = "Forge user namespace used for generated push bookmarks.";
      };
    };

    config = lib.mkMerge [
      {
        persist.user.directories = [
          ".config/gitui"
        ];

        environment.systemPackages = with pkgs; [
          difft
          fzf
          git
          git-lfs
          gitui
          jjFork
          jjOpen
          jjui
          jujutsu
          mergiraf
          watchman
        ];
      }

      (lib.optionalAttrs hasHjemUsers {
        hjem.users.${config.userName} = {
          files.".ssh/allowed_signers".text = lib.concatMapStrings (key: "${cfg.authorEmail} ${key}\n") self.keys-admin;

          xdg.config.files = {
            "jj/config.toml".source = jjConfig;
            "watchman/watchman.json".text = builtins.toJSON {
              ignore_dirs = [
                ".direnv"
                "node_modules"
                "target"
              ];
            };
          };

          rum.programs.git = {
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
                tool = "difftastic";
              };
              difftool.prompt = false;
              "difftool \"difftastic\"".cmd = "${lib.getExe difft} \"$LOCAL\" \"$REMOTE\"";
              push = {
                default = "simple";
                autoSetupRemote = true;
                followTags = true;
              };
              fetch = {
                prune = true;
                pruneTags = true;
                all = true;
                fsckObjects = true;
              };
              receive.fsckObjects = true;
              transfer.fsckObjects = true;
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
        };
      })
    ];
  };
}
