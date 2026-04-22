{ pkgs, ... }:

{
  users.users.sacha = {
    isNormalUser = true;
    description = "Sacha";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" "podman" ];
    shell = pkgs.fish;
  };
}
