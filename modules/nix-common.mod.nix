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
        statix
      ];

      nix = {
        registry.nixpkgs.flake = inputs.nixpkgs;

        settings =
          (import ../nix-config.nix)
          // {
            accept-flake-config = true;
            substituters = [
              "https://cache.nixos.org"
              "https://hyprland.cachix.org"
              "https://cache.numtide.com"
              "https://nix-community.cachix.org"
              "https://sachahjkl.cachix.org"
              "https://install.determinate.systems"
            ];
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
              "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "sachahjkl.cachix.org-1:cepX7PCUV88hCchnh9prZM5V72wRkCf6oSJL6JfgWs0="
              "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
            ];
            trusted-users = ["root" "@wheel"];
          };
      };

      systemd.services.nix-daemon.environment = {
        DETSYS_IDS_TELEMETRY = "disabled";
        NIX_SENTRY_ENDPOINT = "";
      };

      nixpkgs.config.allowUnfree = true;
    };
  };
}
