{inputs, ...}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: {
    devShells = {
      opencode = pkgs.mkShell {
        packages = [
          self'.packages.opencode
          inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.mcp-nixos
          pkgs.git
        ];
      };

      web = pkgs.mkShell {
        packages = with pkgs; [bun deno git just nodejs];
      };
    };
  };
}
