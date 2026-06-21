_: {
  flake.nixosModules.zoxide = {
    persist.user.directories = [".local/share/zoxide"];
  };
}
