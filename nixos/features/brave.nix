{ ... }:

{
  flake.nixosModules.brave = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.brave ];

    preferences.preservation.user.directories = [ ".config/BraveSoftware" ];
  };
}
