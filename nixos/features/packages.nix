{ inputs, self, ... }:

{
  flake.nixosModules.packages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      age
      alsa-utils
      bc
      bcompare
      equibop
      efibootmgr
      fd
      fastfetch
      fff
      git
      jq
      btop
      bat
      eza
      tree
      unzip
      curl
      wget
      htop
      audacity
      ffmpeg-full
      imagemagick
      mediainfo
      mpv
      qemu
      ripgrep
      sbctl
      spice
      spice-gtk
      sublime4
      virt-viewer
      vlc
      inputs.nixos-conf-editor.packages.${pkgs.stdenv.hostPlatform.system}.nixos-conf-editor
      posy-cursors
      pwvucontrol
    ];
  };
}
