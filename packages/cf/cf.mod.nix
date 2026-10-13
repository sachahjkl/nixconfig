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
      version = "1.0.0-beta.14";

      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/cf/-/cf-${version}.tgz";
        hash = "sha256-Cl8wEn+WUfC4Qce37bccOiUKX4UgrBJHPSBi5bVswPM=";
      };

      sourceRoot = "package";
      nodejs = pkgs.nodejs_22;
      npmDepsHash = "sha256-078mupTsf39yUij/1g5+KJmv+q/eYIn1TuXbXS8r91Y=";
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
