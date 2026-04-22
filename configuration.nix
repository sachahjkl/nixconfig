{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/base.nix
    ./modules/desktop.nix
    ./modules/packages.nix
    ./modules/shell.nix
    ./users/sacha/nixos.nix
  ];
}
