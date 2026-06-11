_: {
  flake.nixosModules.serverSsh = {
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
        PubkeyAuthentication = true;
        X11Forwarding = false;
        AcceptEnv = ["SHELLS" "COLORTERM"];
      };
    };

    services.fail2ban.enable = true;
  };
}
