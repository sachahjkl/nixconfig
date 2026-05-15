{ ... }:

{
  flake.nixosModules.brave = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.brave ];

    sacha.preservation.user.directories = [ ".config/BraveSoftware" ];
  };
}
