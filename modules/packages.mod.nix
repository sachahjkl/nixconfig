{self, ...}: {
  flake.nixosModules.packages = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.preferences.git;
    selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
    gitPkg = self.lib.mkGit {inherit pkgs;};
  in {
    options.preferences.git = {
      authorName = lib.mkOption {
        type = lib.types.str;
        default = "sachahjkl";
        description = "Default Git author name for wrapped Git.";
      };

      authorEmail = lib.mkOption {
        type = lib.types.str;
        default = "sacha@sacha.house";
        description = "Default Git author email for wrapped Git.";
      };
    };

    config = {
      preferences.preservation.user.directories = [
        ".config/gitui"
      ];

      programs = {
        bat.enable = true;
        htop.enable = true;
        nh = {
          enable = true;
          package = selfPkgs.nh;
          flake = config.nixConfigPath;
        };
        tmux.enable = true;
      };

      hjem.users.${config.userName}.rum.programs = {
        git = {
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
            mergetool = {
              keepBackup = false;
            };
            "mergetool \"mergiraf\"" = {
              cmd = "mergiraf --mode=merge3 --base=\"$BASE\" --left=\"$LOCAL\" --right=\"$REMOTE\" --output=\"$MERGED\"";
              trustExitCode = true;
            };
            gpg.format = "ssh";
            "gpg \"ssh\"".allowedSignersFile = "~/.ssh/allowed_signers";
            user = {
              name = cfg.authorName;
              email = cfg.authorEmail;
              signingKey = "~/.ssh/id_ed25519_sk.pub";
            };
          };
        };
      };

      environment.systemPackages = with pkgs; [
        # Shell
        selfPkgs.userShell

        # Keep the wrapped git package: aliases and merge tooling depend on
        # extra runtime binaries beyond plain git.
        gitPkg

        # Security
        age

        # Core utilities
        bc
        coreutils
        file
        findutils
        gnutar
        gzip
        gnugrep
        gnused
        less
        moreutils
        rename
        tree
        unzip
        which
        xz
        zstd
        zip

        # Shell and editor helpers
        btop
        carapace
        difftastic
        eza
        fd
        jq
        ripgrep
        ufetch
        zellij

        # Networking and remote access
        curl
        dnsutils
        inetutils
        iproute2
        iputils
        mtr
        netcat-openbsd
        openssh
        rsync
        traceroute
        wget
        whois

        # System administration and inspection
        cronie
        git-lfs
        gitui
        glibc
        lsb-release
        lsof
        pciutils
        plocate
        procps
        psmisc
        pstree
        pv
        usbutils

        # Documentation and diagnostics
        man-db
        man-pages
        nmap

        # Language tooling
        python3
        uv
      ];
    };
  };
}
