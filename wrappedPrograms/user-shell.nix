{ inputs, lib, ... }:

{
  perSystem = { pkgs, self', ... }: {
    packages = {
      userShell = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = self'.packages.fish;
        runtimeInputs = with pkgs; [
          # Only add plain packages here when they do not have a repo wrapper.
          # A plain binary in this shell wrapper can shadow a wrapped one on PATH.
          age
          bat
          btop
          curl
          eza
          fd
          fzf
          htop
          jq
          self'.packages.nh
          self'.packages.nix-fast-build
          ripgrep
          tree
          unzip
          wget
          self'.packages.lf
        ];
        env.EDITOR = lib.getExe pkgs.neovim;
      };

      default = self'.packages.userShell;
    };
  };
}
