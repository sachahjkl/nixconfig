_: {
  flake.nixosModules.wireplumber = {
    preferences.preservation.user.directories = [".local/share/wireplumber"];
  };
}
