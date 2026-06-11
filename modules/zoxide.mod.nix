_: {
  flake.nixosModules.zoxide = {
    preferences.preservation.user.directories = [".local/share/zoxide"];
  };
}
