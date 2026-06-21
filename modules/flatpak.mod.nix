_: {
  flake.nixosModules.flatpak = {
    services.flatpak.enable = true;

    persist = {
      system.directories = ["/var/lib/flatpak"];
      user.directories = [".local/share/flatpak"];
    };
  };
}
