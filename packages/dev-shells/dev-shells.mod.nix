_: {
  perSystem = {
    pkgs,
    self',
    ...
  }: {
    devShells = {
      opencode = pkgs.mkShell {
        packages = [
          self'.packages.opencode2
          pkgs.mcp-nixos
          pkgs.git
        ];
      };

      web = pkgs.mkShell {
        packages = with pkgs; [bun deno git just nodejs];
      };
    };
  };
}
