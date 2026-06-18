_: {
  flake.nixosModules.mosh = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options = {
      withMoshClient = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to install the mosh client.";
      };

      withMoshServer = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable the mosh server integration.";
      };
    };

    config = lib.mkMerge [
      (lib.mkIf config.withMoshClient {
        environment.systemPackages = [pkgs.mosh];
      })

      (lib.mkIf config.withMoshServer {
        programs.mosh = {
          enable = true;
          openFirewall = true;
          withUtempter = true;
        };
      })
    ];
  };
}
