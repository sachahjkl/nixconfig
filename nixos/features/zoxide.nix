{ ... }:

{
  flake.nixosModules.zoxide = {
    sacha.preservation.user.directories = [ ".local/share/zoxide" ];
  };
}
