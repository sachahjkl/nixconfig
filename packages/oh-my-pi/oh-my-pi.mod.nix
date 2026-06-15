{lib, ...}: {
  perSystem = {pkgs, ...}: let
    version = "16.0.1";

    platformMap = {
      x86_64-linux = {
        asset = "omp-linux-x64";
        hash = "sha256-ERpEf4XA7XjjWpnOSB6rSMbKA2eO6OK0MCFiSucnMhU=";
      };
      aarch64-linux = {
        asset = "omp-linux-arm64";
        hash = "sha256-iksSwXlOCZYlzKeJFSSs+wHuspwCeIeL+Mzxs1pzu28=";
      };
    };

    platform =
      platformMap.${pkgs.stdenv.hostPlatform.system}
      or (throw "Unsupported omp platform: ${pkgs.stdenv.hostPlatform.system}");
  in {
    packages.omp = pkgs.stdenv.mkDerivation {
      pname = "omp";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/${platform.asset}";
        inherit (platform) hash;
      };

      nativeBuildInputs = [
        pkgs.makeWrapper
        pkgs.patchelf
      ];

      dontUnpack = true;
      dontPatchELF = true;
      dontStrip = true;

      installPhase = ''
        runHook preInstall

        mkdir -p $out/bin
        install -Dm755 $src $out/bin/omp

        patchelf --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} $out/bin/omp

        wrapProgram $out/bin/omp \
          --set PI_SKIP_VERSION_CHECK 1 \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [pkgs.zlib pkgs.stdenv.cc.cc.lib]}

        runHook postInstall
      '';

      meta = {
        description = "A terminal-based coding agent with multi-model support";
        homepage = "https://github.com/can1357/oh-my-pi";
        changelog = "https://github.com/can1357/oh-my-pi/releases/tag/v${version}";
        license = lib.licenses.mit;
        mainProgram = "omp";
        platforms = ["x86_64-linux" "aarch64-linux"];
        sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      };
    };
  };
}
