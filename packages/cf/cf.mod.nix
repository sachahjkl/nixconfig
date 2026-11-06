_: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    # Cloudflare's unified CLI (`cf`, not Wrangler), packaged from the npm release.
    # Update: bump `version`, regenerate ./package-lock.json from the release's
    # runtime dependencies, then refresh both hashes from the build errors.
    packages.cf = pkgs.buildNpmPackage rec {
      pname = "cf";
      version = "1.0.0-beta.28";

      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/cf/-/cf-${version}.tgz";
        hash = "sha256-GVAu+BzoufP+6e/CsIfoqD/4ZN7sBV7ZurQ5oQ8l+Ss=";
      };

      sourceRoot = "package";
      nodejs = pkgs.nodejs_22;
      npmDepsHash = "sha256-i5M+zJTIXFJggaWWfmKDmSAT4c6iInhgL195y5u4KIc=";
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
