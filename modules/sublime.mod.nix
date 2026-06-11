_: {
  flake.nixosModules.sublime = _: {
    #environment.systemPackages = [ pkgs.sublime4 ];

    #nixpkgs.config.permittedInsecurePackages = [
    #  "openssl-1.1.1w"
    #];

    preferences.preservation.user.directories = [
      ".config/sublime-text"
      ".local/share/sublime-text"
    ];
  };
}
