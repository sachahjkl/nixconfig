{ pkgs, pkgs-unstable, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    age
    alsa-utils
    bcompare
    discord
    efibootmgr
    fd
    fastfetch
    fff
    freeoffice
    git
    kdePackages.ark
    kdePackages.kate
    ripgrep
    sbctl
    sublime4
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.nixos-conf-editor.packages.${pkgs.stdenv.hostPlatform.system}.nixos-conf-editor
  ];
}
