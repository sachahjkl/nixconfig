args: {
  magic = import ./magic.nix args;
  network = import ./network.nix args;
  generators = import ./generators.nix args;
  shell = import ./shell.nix args;
  systems = import ./systems.nix args;
}
