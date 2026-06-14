_: {
  flake.nixosModules.flatpak = {
    services.flatpak.enable = true;

    preferences.preservation = {
      system.directories = ["/var/lib/flatpak"];
      user.directories = [".local/share/flatpak"];
    };
  };
}
