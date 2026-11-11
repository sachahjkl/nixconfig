_: {
  perSystem = {pkgs, ...}: {
    packages.hypr-zoom = pkgs.stdenv.mkDerivation rec {
      pname = "hypr-zoom";
      version = "0.0.3";

      src = pkgs.fetchurl {
        url = "https://github.com/FShou/hypr-zoom/releases/download/v${version}/hypr-zoom";
        hash = "sha256-cFbl5mC+HL4pEayHhzhRvmeoUlCcjAy40I/n8PkhZDc=";
      };

      dontUnpack = true;

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin
        cp $src $out/bin/hypr-zoom
        chmod +x $out/bin/hypr-zoom
        runHook postInstall
      '';

      meta = {
        description = "Hyprland zoom utility";
        homepage = "https://github.com/FShou/hypr-zoom";
        license = pkgs.lib.licenses.mit;
        platforms = pkgs.lib.platforms.linux;
        mainProgram = "hypr-zoom";
      };
    };
  };
}
