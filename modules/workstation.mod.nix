{self, ...}: {
  flake.nixosModules.workstation = {
    config,
    lib,
    ...
  }: {
    imports = [
      self.nixosModules.baseUser
      self.nixosModules.appearance
      self.nixosModules.editor
      self.nixosModules.terminal
      self.nixosModules.ghostty
      self.nixosModules.kitty
      self.nixosModules.kernelHardening
      self.nixosModules.baseSystem
      self.nixosModules.ai
      self.nixosModules.desktop
      self.nixosModules.disko
      self.nixosModules.external-preservation
      self.nixosModules.fish
      self.nixosModules.home-manager
      self.nixosModules.hjem
      self.nixosModules.lf
      self.nixosModules.mosh
      self.nixosModules.moshiHook
      self.nixosModules.neovim
      self.nixosModules.nix
      self.nixosModules.nixCommon
      self.nixosModules.nukeDefaultPackages
      self.nixosModules.opencode
      self.nixosModules.packages
      self.nixosModules.desktop-packages
      self.nixosModules.preservation
      self.nixosModules.sharedSops
      self.nixosModules.user-home
      self.nixosModules.xdgStubs
      self.nixosModules.ssh
      self.nixosModules.steam
      self.nixosModules.sublime
      self.nixosModules.tailscale
      self.nixosModules.vscode
      self.nixosModules.windowsApps
      self.nixosModules.zoxide
    ];

    ai = {
      enable = true;
      herdr.enable = true;
    };

    moshi.enable = true;
    sharedSops.ageKeyFile = lib.mkDefault "/persist/var/lib/sops-nix/key.txt";
    sharedSops.passwordHashSecretName = lib.mkDefault "shared/password-hash";
    network.tailscale.sopsSecretName = lib.mkDefault "tailscale/user-authkey";

    # The OpenCode server starts with the session.
    opencode.session.enable = true;

    nix = {
      buildMachines = [
        {
          hostName = "homelab";
          maxJobs = 8;
          protocol = "ssh-ng";
          speedFactor = 2;
          sshKey = "${config.homeDirectory}/.ssh/far-from-home";
          sshUser = "sacha";
          system = "x86_64-linux";
          supportedFeatures = ["benchmark" "big-parallel" "kvm" "nixos-test"];
        }
      ];
      distributedBuilds = lib.mkDefault true;
      # Local builds are background work: the desktop, its compositor and its programs get the
      # CPU and the disk first.
      daemonCPUSchedPolicy = "batch";
      daemonIOSchedClass = "idle";
    };

    # The Nix daemon connects to the build machine as root, and /root is not persistent.
    # Declare the Tailscale SSH host key of homelab so that root can verify it.
    programs.ssh.knownHosts.homelab = {
      hostNames = ["homelab" "homelab.panthera-python.ts.net" "100.106.51.80"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+2UxmrXUSQ6n+7g9TxNeE1+jMyaeSl/ykFJvvSYRPl";
    };

    editor.vscode.enable = true;
  };
}
