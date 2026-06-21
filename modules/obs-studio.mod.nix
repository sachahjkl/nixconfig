_: {
  flake.nixosModules.obsStudio = {
    persist.user.directories = [".config/obs-studio"];
  };
}
