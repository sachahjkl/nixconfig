{ self, ... }:

{
  perSystem = { pkgs, self', ... }:
    let
      gitPkg = self.lib.mkGit { inherit pkgs; };
    in
    {
      devShells = {
        opencode = pkgs.mkShell {
          packages = [ self'.packages.opencode gitPkg ];
        };

        web = pkgs.mkShell {
          packages = with pkgs; [ bun deno gitPkg just nodejs ];
        };
      };
    };
}
