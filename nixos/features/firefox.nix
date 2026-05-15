{ ... }:

{
  flake.nixosModules.firefox = {
    programs.firefox.enable = true;

    sacha.preservation.user.directories = [ ".mozilla" ];
  };
}
