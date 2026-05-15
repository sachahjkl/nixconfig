{ ... }:

{
  flake.nixosModules.steam = {
    preferences.preservation.user.directories = [ ".local/share/Steam" ];
  };
}
