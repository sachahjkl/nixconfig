_: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    # Cloudflare's unified CLI (`cf`, not Wrangler), packaged from the npm release.
    # Update with `nix run .#update -- cf`. It bumps `version`, regenerates
    # ./package-lock.json and refreshes both hashes.
    packages.cf = pkgs.buildNpmPackage rec {
      pname = "cf";
      version = "1.0.0-beta.29";

      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/cf/-/cf-${version}.tgz";
        hash = "sha256-kU8D738RYGExOtD2pcghlrzOPTETsIj5mJEz+o3JsKI=";
      };

      sourceRoot = "package";
      nodejs = pkgs.nodejs_22;
      npmDepsHash = "sha256-88M2uJzhTV4Ee48vtKnhliKpFG3CTcIYwySM4YacBSA=";
      npmFlags = ["--ignore-scripts"];
      dontNpmBuild = true;

      # The published package.json lists devDependencies that point outside the
      # tarball; only the runtime dependencies are installed.
      postPatch = ''
        ${lib.getExe pkgs.jq} 'del(.devDependencies, .scripts)' package.json > package.json.tmp
        mv package.json.tmp package.json
        cp ${./package-lock.json} package-lock.json
      '';

      meta = {
        description = "Cloudflare CLI for the public Cloudflare API and Workers projects";
        homepage = "https://developers.cloudflare.com/cf/";
        license = with lib.licenses; [mit asl20];
        mainProgram = "cf";
      };
    };
  };
}
