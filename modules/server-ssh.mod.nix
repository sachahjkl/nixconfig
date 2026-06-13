_: {
  flake.nixosModules.serverSsh = {
    services.fail2ban.enable = true;
  };
}
