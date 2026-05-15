{ inputs, self, ... }:

{
  flake.nixosModules.packages = { config, pkgs, ... }:
    let
      selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
      gitPkg = self.lib.mkGit {
        inherit pkgs;
        authorName = config.sacha.git.authorName;
        authorEmail = config.sacha.git.authorEmail;
      };
    in
    {
      options.sacha.git = {
        authorName = pkgs.lib.mkOption {
          type = pkgs.lib.types.str;
          default = "sachahjkl";
          description = "Default Git author name for wrapped Git.";
        };

        authorEmail = pkgs.lib.mkOption {
          type = pkgs.lib.types.str;
          default = "sacha@sacha.house";
          description = "Default Git author email for wrapped Git.";
        };
      };

      config.environment.systemPackages = with pkgs; [
        selfPkgs.environment
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
        direnv
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
        inputs.nixos-conf-editor.packages.${pkgs.stdenv.hostPlatform.system}.nixos-conf-editor
      ];
    };
}
