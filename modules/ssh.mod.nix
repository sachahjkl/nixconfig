_:

{
  flake.nixosModules.ssh = { config, lib, ... }: {
    options.preferences.ssh.identityKey = lib.mkOption {
      type = lib.types.str;
      default = "~/.ssh/id_ed25519_sk";
      description = "Primary SSH identity key path.";
    };

    config.hjem.users.${config.userName} = {
      xdg.config.files."ssh/config".text = ''
        Host *
          CheckHostIP yes
          ControlMaster auto
          ControlPath ~/.cache/ssh/master-%r@%n:%p
          ControlPersist 60m
          ForwardX11 no
          ForwardX11Trusted no
          ServerAliveCountMax 3
          ServerAliveInterval 0
          SetEnv COLORTERM=truecolor TERM=xterm-256color
          UserKnownHostsFile ~/.ssh/known_hosts

        Host github.com
          IdentitiesOnly yes
          IdentityFile ${config.preferences.ssh.identityKey}

        Host gitlab.com
          IdentitiesOnly yes
          IdentityFile ${config.preferences.ssh.identityKey}
      '';

      rum.programs.fish.aliases.mosh = "mosh --no-init";
    };
  };
}
