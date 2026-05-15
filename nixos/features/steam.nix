{ ... }:

{
  flake.nixosModules.steam = {
    sacha.preservation.user.directories = [ ".local/share/Steam" ];
  };
}
