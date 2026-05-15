{ ... }:

{
  flake.nixosModules.neovim = {
    sacha.preservation.user.directories = [
      ".config/nvim"
      ".local/share/nvim"
    ];
  };
}
