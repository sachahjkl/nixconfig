{inputs, ...}: {
  # bootvine (codeberg.org/wvhulle/bootvine): the boot console shows a live
  # tree of systemd's jobs, from the initrd (a systemd initrd, NixOS's by
  # default) to the display manager, and again at shutdown. It asks the LUKS
  # passphrase itself.
  flake.nixosModules.bootvine = {lib, ...}: {
    imports = [inputs.bootvine.nixosModules.default];

    services.bootvine.enable = true;

    # Plymouth would cover the console and ask the passphrase first: bootvine
    # takes its place.
    boot.plymouth.enable = lib.mkForce false;
  };
}
