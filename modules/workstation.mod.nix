{self, ...}: {
  flake.nixosModules.workstation = {lib, ...}: {
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

    opencode.homelabServerUrl = lib.mkDefault "http://homelab:4096";

    editor.vscode.enable = true;
  };
}
