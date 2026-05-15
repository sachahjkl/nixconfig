{ inputs, lib, ... }:

{
  perSystem = { pkgs, self', ... }: {
    packages = {
      environment = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = self'.packages.fish;
        runtimeInputs = with pkgs; [
          age
          bat
          btop
          curl
          eza
          fd
          fzf
          htop
          jq
          nil
          self'.packages.nh
          self'.packages.nix-fast-build
          nixd
          ripgrep
          statix
          tree
          unzip
          wget
          self'.packages.lf
          self'.packages.git
        ];
        env.EDITOR = lib.getExe pkgs.neovim;
      };

      default = self'.packages.environment;
    };
  };
}
