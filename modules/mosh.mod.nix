_: {
  flake.nixosModules.mosh = {
    programs.mosh = {
      enable = true;
      openFirewall = true;
      withUtempter = true;
    };
  };
}
