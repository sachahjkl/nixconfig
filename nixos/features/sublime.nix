{ ... }:

{
  flake.nixosModules.sublime = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.sublime4 ];

    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.1.1w"
    ];

    sacha.preservation.user.directories = [
      ".config/sublime-text"
      ".local/share/sublime-text"
    ];
  };
}
