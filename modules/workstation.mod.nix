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
      distributedBuilds = true;
      settings = {
        substituters = lib.mkBefore ["http://homelab:5000"];
        trusted-public-keys = lib.mkAfter ["homelab-cache-1:ZaUHSv8slKsAKc9kd0AGI8p1HUjUumfho7ShgUVlnUg="];
      };
    };

    opencode.homelabServerUrl = lib.mkDefault "http://homelab:4096";

    editor.vscode.enable = true;
  };
}
