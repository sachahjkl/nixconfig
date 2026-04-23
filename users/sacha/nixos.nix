{ pkgs, ... }:

{
  users.users.sacha = {
    isNormalUser = true;
    description = "Sacha";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" "podman" "libvirtd" "kvm" ];
    shell = pkgs.fish;
  };
}
