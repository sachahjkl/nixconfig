{ ... }:

{
  flake.nixosModules.neovim = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.neovim ];

    sacha.preservation.user.directories = [
      ".config/nvim"
      ".local/share/nvim"
    ];
  };
}
