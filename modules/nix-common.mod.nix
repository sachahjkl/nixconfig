{inputs, ...}: {
  flake.nixosModules.nixCommon = {pkgs, ...}: {
    imports = [inputs.determinate.nixosModules.default];

    config = {
      documentation = {
        man.cache.enable = false;
        nixos.enable = false;
      };

      environment.systemPackages = with pkgs; [
        alejandra
        deadnix
        manix
        nil
        nix-inspect
        nix-init
        nix-output-monitor
        nix-tree
        nixd
        prek
        statix
      ];

      nix = {
        registry.nixpkgs.flake = inputs.nixpkgs;

        optimise.automatic = true;

        settings = (import ../nix-config.nix) // {accept-flake-config = true;};
      };

      systemd.services.nix-daemon.environment = {
        DETSYS_IDS_TELEMETRY = "disabled";
        NIX_SENTRY_ENDPOINT = "";
      };

      nixpkgs.config.allowUnfree = true;
    };
  };
}
