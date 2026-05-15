{ self, ... }:

{
  flake.nixosModules.sacha-hjem = { config, ... }:
    let
      user = config.sacha.userName;
      home = config.sacha.homeDirectory;
      sshIdentityKey = "~/.ssh/id_ed25519_sk";
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

    };
}
