{ ... }:

{
  flake.nixosModules.flatpak = {
    services.flatpak.enable = true;

    preferences.preservation.system.directories = [ "/var/lib/flatpak" ];
    preferences.preservation.user.directories = [ ".local/share/flatpak" ];
  };
}
