{ self, ... }:

{
  flake.nixosModules.sacha-hjem = { config, lib, pkgs, ... }:
    let
      user = config.sacha.userName;
      home = config.sacha.homeDirectory;
      gitPrincipal = "sacha@sacha.house";
      sshIdentityKey = "~/.ssh/id_ed25519_sk";
      sshSigningKey = "~/.ssh/id_ed25519_sk.pub";
      selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      hjem = {
        clobberByDefault = true;
        users.${user} = {
          enable = true;
          user = user;
          directory = home;

          environment.sessionVariables = {
            EDITOR = "nvim";
            TERMINAL = "kitty";
          };

          files = {
            ".face.icon".source = config.sacha.assets.faceIcon;
            ".ssh/config".text = ''
              Host *
                CheckHostIP yes
                ControlMaster no
                ControlPath ~/.ssh/master-%r@%n:%p
                ControlPersist no
                ForwardX11 no
                ForwardX11Trusted no
                ServerAliveCountMax 3
                ServerAliveInterval 0
                UserKnownHostsFile ~/.ssh/known_hosts

              Host github.com
                IdentitiesOnly yes
                IdentityFile ${sshIdentityKey}

              Host gitlab.com
                IdentitiesOnly yes
                IdentityFile ${sshIdentityKey}
            '';
          };

          xdg.config.files = {
            "fish/config.fish".text = ''
              set fish_greeting
              alias rebuild-switch 'sudo nixos-rebuild switch --flake ${config.sacha.dotfilesPath}#${config.networking.hostName}'
              ${lib.getExe pkgs.starship} init fish | source
              ${lib.getExe pkgs.zoxide} init fish | source
              ${lib.getExe pkgs.carapace} _carapace fish | source
              direnv hook fish | source
            '';

            "git/config".text = ''
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
              [user]
                name = sachahjkl
                email = sacha@sacha.house
                signingKey = ${sshSigningKey}
              [gpg]
                format = ssh
              [gpg "ssh"]
                allowedSignersFile = ~/.ssh/allowed_signers
              [commit]
                gpgSign = true
            '';

            "mimeapps.list".text = ''
              [Default Applications]
              application/xhtml+xml=brave-browser.desktop
              inode/directory=thunar.desktop
              text/html=brave-browser.desktop
              x-scheme-handler/chrome=brave-browser.desktop
              x-scheme-handler/http=brave-browser.desktop
              x-scheme-handler/https=brave-browser.desktop
            '';
          };
        };
      };

      environment.systemPackages = [
        selfPkgs.environment
        selfPkgs.git
        selfPkgs.terminal
        pkgs.brave
        pkgs.carapace
        pkgs.direnv
        pkgs.difftastic
        pkgs.fzf
        pkgs.git-lfs
        pkgs.gitui
        pkgs.mergiraf
        pkgs.neovim
        selfPkgs.nh
        selfPkgs.nix-fast-build
        pkgs.opencode
        pkgs.starship
        pkgs.tmux
        pkgs.zellij
        pkgs.zoxide
      ];
    };
}
