_: {
  flake.nixosModules.firefox = {pkgs, ...}: {
    programs.firefox.enable = true;

    environment.systemPackages = [pkgs.firefox];

    persist.user.directories = [".mozilla"];
  };
}
