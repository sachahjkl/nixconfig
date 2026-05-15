{ ... }:

{
  flake.nixosModules.wireplumber = {
    sacha.preservation.user.directories = [ ".local/share/wireplumber" ];
  };
}
