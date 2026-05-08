{ config, lib, pkgs, osConfig, inputs, ... }:

let
  gitPrincipal = "sacha@sacha.house";
  sshIdentityKey = "~/.ssh/id_ed25519_sk";
  sshSigningKey = "~/.ssh/id_ed25519_sk.pub";
  isKDE = lib.elem osConfig.desktop.environment [ "kde" "both" ];
in
{
  imports = [ inputs.helium.homeModules.helium ];

  home.username = osConfig.sacha.userName;
  home.homeDirectory = osConfig.sacha.homeDirectory;
  home.stateVersion = "26.05";

  programs.fish = {
    enable = true;
    shellInit = ''
      set fish_greeting
    '';
    shellAliases = {
      rebuild-switch = "sudo nixos-rebuild switch --flake ${osConfig.sacha.dotfilesPath}#${osConfig.networking.hostName}";
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      directory.truncation_length = 5;
    };
  };

  programs.carapace = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.chromium.enable = true;

  programs.helium = {
    enable = true;
    defaultBrowser = true;
    extraFlags = [ "--force-dark-mode" ];
  };

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

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        checkHostIP = true;
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
        forwardX11 = false;
        forwardX11Trusted = false;
        serverAliveCountMax = 3;
        serverAliveInterval = 0;
        userKnownHostsFile = "~/.ssh/known_hosts";
      };
      "github.com" = {
        identitiesOnly = true;
        identityFile = sshIdentityKey;
      };
      "gitlab.com" = {
        identitiesOnly = true;
        identityFile = sshIdentityKey;
      };
    };
  };

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
      gpg = {
        format = "ssh";
        ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      };
    };
    signing = {
      signByDefault = true;
      key = sshSigningKey;
    };
  };

  home.activation.gitAllowedSigners = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    signer_file="${config.home.homeDirectory}/.ssh/allowed_signers"
    public_key_file="${config.home.homeDirectory}/.ssh/id_ed25519_sk.pub"

    if [ -f "$public_key_file" ]; then
      mkdir -p "$(dirname "$signer_file")"
      key=$(tr -d '\n' < "$public_key_file")
      printf '%s %s\n' '${gitPrincipal}' "$key" > "$signer_file"
      chmod 644 "$signer_file"
    fi
  '';

  programs.opencode = {
    enable = true;
    package = pkgs.opencode;
  };

  programs.gitui = {
    enable = true;
    package = pkgs.gitui;
  };

  programs.difftastic = {
    enable = true;
    git.enable = true;
  };

  programs.mergiraf.enable = true;

  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts.emoji = [ "Noto Color Emoji" ];

  home.file.".face.icon" = { source = osConfig.sacha.assets.faceIcon; };

  xdg.configFile = lib.mkMerge [
    (lib.mkIf isKDE {
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
          KeyRepeat=repeat
          RepeatRate=40
          RepeatDelay=200
          NumLock=0

          [Mouse]
          cursorTheme=${osConfig.sacha.theme.cursor}
          cursorSize=${toString osConfig.sacha.theme.cursorSize}

          [Libinput][Defaults]
          PointerAcceleration=0.20
          PointerAccelerationProfile=1
        '';
      };

      "kwinrc" = {
        force = true;
        text = ''
          [org.kde.kdecoration2]
          library=org.kde.kwin.aurorae
          theme=kwin4_decoration_qml_plastik

          [Plugins]
          dimscreenEnabled=false
          fadeEnabled=false
          fadingpopupsEnabled=false
          fallapartEnabled=false
          glideEnabled=false
          loginEnabled=false
          logoutEnabled=false
          magiclampEnabled=false
          maximizeEnabled=false
          morphingpopupsEnabled=false
          overviewEnabled=false
          scaleEnabled=false
          slideEnabled=false
          slidingpopupsEnabled=false
          squashEnabled=false
          startupfeedbackEnabled=false
          thumbnailasideEnabled=false
          translucencyEnabled=false
          windowviewEnabled=false
          wobblywindowsEnabled=false
        '';
      };
    })
  ];

  xdg.desktopEntries.sublime_text = {
    name = "Sublime Text";
    exec = "sublime_text --enable-features=UseOzonePlatform --ozone-platform=wayland %F";
    icon = "sublime_text";
    type = "Application";
    categories = [ "TextEditor" "Development" ];
    mimeType = [ "text/plain" ];
  };

  home.packages = with pkgs; [
    brave

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
