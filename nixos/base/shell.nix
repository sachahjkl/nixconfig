{ ... }:

{
  flake.nixosModules.shell = { ... }: {
    # Enable fish at system level so NixOS vendor completions are available.
    # Shell config, integrations, and plugins are managed via hjem/wrappers.
    programs.fish.enable = true;
  };
}
