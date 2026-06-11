{ ... }:

{
  perSystem = { pkgs, ... }: {
    packages.windows-10-theme = pkgs.stdenvNoCC.mkDerivation {
      pname = "windows-10-theme";
      version = "2025-11-24";

      src = pkgs.fetchFromGitHub {
        owner = "B00merang-Project";
        repo = "Windows-10-Dark";
        rev = "10e4bd54b8ca14f5efb741c891d19090493ff476";
        hash = "sha256-cTQW+k/Uk14iqK2yRXQ2Zv7Bwr/eNnPQFDemsgD8M0s=";
      };

      installPhase = ''
        runHook preInstall

        mkdir -p "$out/share/themes/Windows-10-Dark"
        cp -R . "$out/share/themes/Windows-10-Dark"

        runHook postInstall
      '';

      meta = {
        description = "Windows 10 Dark GTK theme";
        homepage = "https://github.com/B00merang-Project/Windows-10-Dark";
        license = pkgs.lib.licenses.gpl3Only;
        platforms = pkgs.lib.platforms.linux;
      };
    };
  };
}
