{ self, ... }:

{
  flake.keys = {
    # Dedicated agenix SSH key. The private key is stored in Bitwarden.
    # Do not use the YubiKey resident sk-* SSH key here; age needs a normal decryptable SSH key.
    admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJMYomE72hDxOemhx4f8EfHw1vDwAFAbE405j8IOL7d/ sacha-agenix";

    house-desktop = self.keys.admin;
    house-laptop = self.keys.admin;
    homelab = self.keys.admin;
    wsl = self.keys.admin;
  };

  flake.keys-admin = [ self.keys.admin ];
}
