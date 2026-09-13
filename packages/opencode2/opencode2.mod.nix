_: {
  perSystem = {pkgs, ...}: let
    version = "0.0.0-beta-19507";
    opencode2 = pkgs.stdenvNoCC.mkDerivation {
      pname = "opencode2";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@opencode/cli-linux-x64/-/cli-linux-x64-${version}.tgz";
        hash = "sha256-/Ano8WI+3MaOBXwFTvIHGFS45AScgmOrgLBlno4yHJU=";
      };

      nativeBuildInputs = [pkgs.autoPatchelfHook];
      dontStrip = true;

      installPhase = ''
        runHook preInstall
        install -Dm755 bin/opencode "$out/bin/opencode2"
        runHook postInstall
      '';

      doInstallCheck = true;
      installCheckPhase = ''
        export HOME="$TMPDIR"
        $out/bin/opencode2 --version >version-output || true
        grep -Fx "opencode v${version}" version-output
      '';

      meta = {
        description = "OpenCode V2 terminal client";
        homepage = "https://opencode.ai";
        license = pkgs.lib.licenses.mit;
        mainProgram = "opencode2";
        platforms = ["x86_64-linux"];
      };
    };
  in {
    packages.opencode2 = opencode2;
    checks.opencode2 = opencode2;
  };
}
