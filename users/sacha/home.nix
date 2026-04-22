{ pkgs, pkgs-unstable, ... }:

let
  gpgSigningKey = "21D64EBC463D12DFE373AE4F1EFE264F809A2118";
in
{
  home.username = "sacha";
  home.homeDirectory = "/home/sacha";
  home.stateVersion = "25.11";

  programs.fish = {
    enable = true;
    shellInit = ''
      set fish_greeting
    '';
    interactiveShellInit = ''
      set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
      gpgconf --launch gpg-agent >/dev/null 2>&1
    '';
    shellAliases = {
      rebuild-switch = "sudo nixos-rebuild switch --flake /home/sacha/Devel/dotfiles/#nixos";
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      character = {
        success_symbol = ">";
        error_symbol = "[>](red)";
      };
      directory.truncation_length = 5;
    };
  };

  programs.carapace = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.chromium.enable = true;

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.vscode = {
    enable = true;
  };

  programs.neovim.enable = true;

  programs.git = {
    enable = true;
    lfs.enable = true;
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
      user = {
        name = "sachahjkl";
        email = "sacha@sacha.house";
      };
      gpg.format = "openpgp";
    };
    signing = {
      signByDefault = true;
      key = gpgSigningKey;
    };
  };

  programs.gpg = {
    enable = true;
    settings.default-key = gpgSigningKey;
  };

  services.gpg-agent = {
    enable = true;
    enableFishIntegration = true;
    enableSshSupport = true;
    defaultCacheTtl = 1800;
    defaultCacheTtlSsh = 1800;
    maxCacheTtl = 7200;
    maxCacheTtlSsh = 7200;
    pinentry.package = pkgs.pinentry-qt;
    sshKeys = [ "08C261B4109E7FED5761D7C296AEA7ACE17BBBE8" ];
  };

  programs.opencode = {
    enable = true;
    package = pkgs-unstable.opencode;
  };

  programs.gitui = {
    enable = true;
    package = pkgs-unstable.gitui;
  };

  programs.difftastic = {
    enable = true;
    git.enable = true;
  };

  programs.mergiraf.enable = true;

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Nerd Fonts (icons + programming ligatures)
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.noto

    # Emoji
    noto-fonts-color-emoji

    # General coverage
    noto-fonts
    noto-fonts-cjk-sans

    # Liberation (metric-compatible with Arial/Times/Courier)
    liberation_ttf
  ];
}
