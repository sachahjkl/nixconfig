_: {
  perSystem = {pkgs, ...}: {
    devShells = {
      web = pkgs.mkShell {
        packages = with pkgs; [bun deno git just nodejs];
      };
    };
  };
}
