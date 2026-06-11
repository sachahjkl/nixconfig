_:

{
  flake.nixosModules.neovim = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.neovim ];

    preferences.preservation.user.directories = [
      ".config/nvim"
      ".local/share/nvim"
    ];
  };
}
