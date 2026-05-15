{ ... }:

{
  flake.nixosModules.direnv = {
    sacha.preservation.user.directories = [ ".local/share/direnv" ];
  };
}
