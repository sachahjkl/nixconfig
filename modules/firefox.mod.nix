_: {
  flake.nixosModules.firefox = {pkgs, ...}: {
    programs.firefox.enable = true;

    environment.systemPackages = [pkgs.firefox];

    preferences.preservation.user.directories = [".mozilla"];
  };
}
