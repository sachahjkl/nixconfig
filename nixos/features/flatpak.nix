{ ... }:

{
  flake.nixosModules.flatpak = {
    services.flatpak.enable = true;

    sacha.preservation.system.directories = [ "/var/lib/flatpak" ];
    sacha.preservation.user.directories = [ ".local/share/flatpak" ];
  };
}
