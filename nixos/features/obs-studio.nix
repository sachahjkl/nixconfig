{ ... }:

{
  flake.nixosModules.obsStudio = {
    preferences.preservation.user.directories = [ ".config/obs-studio" ];
  };
}
