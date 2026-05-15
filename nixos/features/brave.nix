{ ... }:

{
  flake.nixosModules.brave = {
    sacha.preservation.user.directories = [ ".config/BraveSoftware" ];
  };
}
