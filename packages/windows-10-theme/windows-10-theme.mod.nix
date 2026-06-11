{ ... }:

{
  perSystem = { pkgs, ... }: {
    packages.windows-10-theme = pkgs.stdenvNoCC.mkDerivation {
      pname = "windows-10-theme";
      version = "2025-08-22";

      src = pkgs.fetchFromGitHub {
        owner = "B00merang-Project";
        repo = "Windows-10";
        rev = "3a4116603b66a9adcb78f3987d7ea6f01de1cbce";
        hash = "sha256-1s/i19k7dAVfKWEqqAciOQVV5t7UMOnCjd8Aa575VIk=";
      };

      installPhase = ''
        runHook preInstall

        mkdir -p "$out/share/themes/Windows-10"
        cp -R . "$out/share/themes/Windows-10"

        runHook postInstall
      '';

      meta = {
        description = "Windows 10 GTK theme";
        homepage = "https://github.com/B00merang-Project/Windows-10";
        license = pkgs.lib.licenses.gpl3Only;
        platforms = pkgs.lib.platforms.linux;
      };
    };
  };
}
