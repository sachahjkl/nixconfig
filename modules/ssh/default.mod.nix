{self, ...}: {
  flake.nixosModules.ssh = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    authorizedKeys = self.keys-admin;
    hasUserName = lib.hasAttrByPath ["userName"] options;
    hasHomeDirectory = lib.hasAttrByPath ["homeDirectory"] options;
    hasFishAliases = lib.hasAttrByPath ["programs" "fish" "shellAliases"] options;
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
    hasPreservationDirs = lib.hasAttrByPath ["persist" "user" "directories"] options;
    hasPreservationFiles = lib.hasAttrByPath ["persist" "system" "files"] options;
    hasSopsSecrets = lib.hasAttrByPath ["sops" "secrets"] options;
  in {
    imports = [self.nixosModules.yubikeySshKeys];

    options.ssh.identityKey = lib.mkOption {
      type = lib.types.str;
      default = "~/.ssh/id_ed25519_sk";
      description = "Primary SSH identity key path.";
    };

    config = lib.mkMerge [
      {
        services.openssh = {
          enable = true;
          hostKeys = [
            {
              path = "/etc/ssh/ssh_host_ed25519_key";
              type = "ed25519";
            }
          ];
          openFirewall = true;
          settings = {
            KbdInteractiveAuthentication = false;
            PasswordAuthentication = false;
            PermitRootLogin = "prohibit-password";
            PubkeyAuthentication = true;
            X11Forwarding = false;
            AcceptEnv = ["SHELLS" "COLORTERM"];
          };
        };
      }

      (lib.optionalAttrs hasUserName {
        users.users.${config.userName}.openssh.authorizedKeys.keys = authorizedKeys;
      })

      (lib.optionalAttrs hasPreservationFiles (let
        persistentSshDir = "${toString config.persist.persistentStoragePath}/etc/ssh";
        persistentEd25519Key = "${persistentSshDir}/ssh_host_ed25519_key";
        persistentEd25519Pub = "${persistentSshDir}/ssh_host_ed25519_key.pub";
      in {
        persist.system.files = [
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
        ];

        system.activationScripts.preservedSshHostKey.text = ''
          # Preserved SSH host keys can get stuck in a bad state if preservation
          # captured an empty file or the private key ended up with loose
          # permissions. When that happens, sshd-keygen cannot replace the
          # mounted file and sshd either ignores the key or fails to start.
          # Repair the persisted source before the bind mounts are used so the
          # machine keeps a stable host identity across rebuilds and reboots.
          install -d -m 0755 ${persistentSshDir}

          if [ ! -s ${persistentEd25519Key} ] || [ ! -s ${persistentEd25519Pub} ]; then
            rm -f ${persistentEd25519Key} ${persistentEd25519Pub}
            ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -f ${persistentEd25519Key}
          fi

          chmod 0600 ${persistentEd25519Key}
          chmod 0644 ${persistentEd25519Pub}
        '';

        # Enforce host key permissions on every boot in case preservation,
        # a bind mount, or a manual edit left the private key too open.
        systemd.tmpfiles.rules = [
          "z ${persistentSshDir}/ssh_host_ed25519_key 0600 root root -"
          "z ${persistentSshDir}/ssh_host_ed25519_key.pub 0644 root root -"
        ];
      }))

      (lib.optionalAttrs hasPreservationDirs {
        persist.user.directories = [".cache/ssh"];
      })

      (lib.optionalAttrs (hasUserName && hasHomeDirectory) {
        systemd.tmpfiles.rules = [
          "d ${config.homeDirectory}/.cache/ssh 0700 ${config.userName} users -"
        ];
      })

      (lib.optionalAttrs (hasHjemUsers && hasUserName) {
        hjem.users.${config.userName} = {
          xdg.config.files = {
            "ssh/config".text = ''
              Host *
                CheckHostIP yes
                ControlMaster auto
                ControlPath ~/.cache/ssh/master-%r@%n:%p
                ControlPersist 60m
                ForwardX11 no
                ForwardX11Trusted no
                IdentitiesOnly yes
                IdentityFile ${config.ssh.identityKey}
                ServerAliveCountMax 3
                ServerAliveInterval 0
                SetEnv COLORTERM=truecolor TERM=xterm-256color
                UserKnownHostsFile ~/.ssh/known_hosts

              Host homelab
                User deploy
                IdentitiesOnly yes
                IdentityFile ~/.ssh/far-from-home
            '';
          };

          files.".ssh/far-from-home.pub".text = "${self.keys."far-from-home"}\n";
        };
      })

      (lib.optionalAttrs (hasSopsSecrets && hasUserName && hasHomeDirectory) {
        sops.secrets."ssh/far-from-home/private" = {
          sopsFile = self + /secrets/shared.yaml;
          path = "${config.homeDirectory}/.ssh/far-from-home";
          owner = config.userName;
          group = "users";
          mode = "0600";
        };
      })

      (lib.optionalAttrs hasFishAliases {
        programs.fish.shellAliases.mosh = "mosh --no-init";
      })
    ];
  };
}
