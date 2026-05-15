{ ... }:

{
  flake.nixosModules.ssh = { config, lib, ... }: {
    options.preferences.ssh.identityKey = lib.mkOption {
      type = lib.types.str;
      default = "~/.ssh/id_ed25519_sk";
      description = "Primary SSH identity key path.";
    };

    config.hjem.users.${config.userName}.files.".ssh/config".text = ''
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
        IdentityFile ${config.preferences.ssh.identityKey}

      Host gitlab.com
        IdentitiesOnly yes
        IdentityFile ${config.preferences.ssh.identityKey}
    '';
  };
}
