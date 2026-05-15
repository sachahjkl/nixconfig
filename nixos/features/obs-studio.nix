{ ... }:

{
  flake.nixosModules.obsStudio = {
    sacha.preservation.user.directories = [ ".config/obs-studio" ];
  };
}
