{ ... }:

{
  flake.nixosModules.fish = {
    sacha.preservation.user.directories = [ ".local/share/fish" ];
  };
}
