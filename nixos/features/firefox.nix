{ ... }:

{
  flake.nixosModules.firefox = { pkgs, ... }: {
    programs.firefox.enable = true;

    environment.systemPackages = [ pkgs.firefox ];

    sacha.preservation.user.directories = [ ".mozilla" ];
  };
}
