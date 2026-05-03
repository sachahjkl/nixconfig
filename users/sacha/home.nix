{ pkgs, pkgs-unstable, osConfig, ... }:

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
      rebuild-switch = "sudo nixos-rebuild switch --flake /home/sacha/Devel/dotfiles#${osConfig.networking.hostName}";
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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
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

  home.file.".face.icon" = { source = ./face.icon; };

  xdg.configFile = {
    "kdeglobals" = {
      force = true;
      text = ''
      [Icons]
      Theme=Papirus

      [KDE]
      widgetStyle=Fusion

      [UiSettings]
      ColorScheme=Plastik
      '';
    };

    "kcminputrc" = {
      force = true;
      text = ''
        [Keyboard]
        KeyRepeat=true
        RepeatRate=20
        RepeatDelay=220

        [Mouse]
        cursorTheme=Posy_Cursor_Black_125_175
        cursorSize=48
      '';
    };

    "kwinrc" = {
      force = true;
      text = ''
        [org.kde.kdecoration2]
        library=org.kde.kwin.aurorae
        theme=kwin4_decoration_qml_plastik

        [Plugins]
        kwin4_effect_dimscreenEnabled=false
        kwin4_effect_fadeEnabled=false
        kwin4_effect_fadingpopupsEnabled=false
        kwin4_effect_fallapartEnabled=false
        kwin4_effect_glideEnabled=false
        kwin4_effect_loginEnabled=false
        kwin4_effect_logoutEnabled=false
        kwin4_effect_magiclampEnabled=false
        kwin4_effect_maximizeEnabled=false
        kwin4_effect_morphingpopupsEnabled=false
        kwin4_effect_overviewEnabled=false
        kwin4_effect_scaleEnabled=false
        kwin4_effect_slideEnabled=false
        kwin4_effect_slidingpopupsEnabled=false
        kwin4_effect_squashEnabled=false
        kwin4_effect_startupfeedbackEnabled=false
        kwin4_effect_thumbnailasideEnabled=false
        kwin4_effect_translucencyEnabled=false
        kwin4_effect_windowviewEnabled=false
        kwin4_effect_wobblywindowsEnabled=false
      '';
    };
  };

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

    # KDE themes
    papirus-icon-theme
  ];
}
