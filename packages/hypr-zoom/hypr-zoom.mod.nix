{ ... }:

{
  perSystem = { pkgs, ... }: {
    packages.hypr-zoom = pkgs.stdenv.mkDerivation {
      pname = "hypr-zoom";
      version = "0.0.3";

      src = pkgs.fetchurl {
        url = "https://github.com/FShou/hypr-zoom/releases/download/v0.0.3/hypr-zoom";
        sha256 = "0dv447wz1rwgs2w0r34wa19ahrxya4w8g1xc24lvw75yc3kfamkh";
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
