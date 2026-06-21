_: {
  flake.nixosModules.wireplumber = {
    persist.user.directories = [".local/share/wireplumber"];
  };
}
