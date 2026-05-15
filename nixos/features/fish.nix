{ ... }:

{
  flake.nixosModules.fish = {
    preferences.preservation.user.directories = [ ".local/share/fish" ];
  };
}
