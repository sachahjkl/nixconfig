{ inputs, self, ... }:

{
  flake.nixosModules.packages = { config, lib, pkgs, ... }:
    let
      cfg = config.preferences.git;
      selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
      gitPkg = self.lib.mkGit {
        inherit pkgs;
        authorName = cfg.authorName;
        authorEmail = cfg.authorEmail;
      };
      nixos-conf-editor = inputs.nixos-conf-editor.packages.${pkgs.stdenv.hostPlatform.system}.nixos-conf-editor;
    in
    {
      options.preferences.git = {
        authorName = lib.mkOption {
          type = lib.types.str;
          default = "sachahjkl";
          description = "Default Git author name for wrapped Git.";
        };

        authorEmail = lib.mkOption {
          type = lib.types.str;
          default = "sacha@sacha.house";
          description = "Default Git author email for wrapped Git.";
        };
      };

      config.environment.systemPackages = with pkgs; [
        selfPkgs.userShell
        gitPkg
        selfPkgs.nh
        selfPkgs.nix-fast-build
        age
        alsa-utils
        audacity
        bat
        bc
        bcompare
        btop
        carapace
        curl
        difftastic
        equibop
        efibootmgr
        eza
        fastfetch
        fd
        fff
        ffmpeg-full
        fzf
        git-lfs
        gitui
        htop
        imagemagick
        jq
        mediainfo
        mpv
        opencode
        posy-cursors
        pwvucontrol
        qemu
        ripgrep
        sbctl
        spice
        spice-gtk
        starship
        sublime4
        tmux
        tree
        unzip
        virt-viewer
        vlc
        wget
        zellij
        zoxide
        nixos-conf-editor
      ];
    };
}
