_: {
  perSystem = {pkgs, ...}: let
    version = "0.2.39";
    platform =
      if pkgs.stdenv.hostPlatform.system == "x86_64-linux"
      then {
        asset = "moshi-hook_Linux_x86_64.tar.gz";
        hash = "sha256-CAd+x0Bb4+b9z832Sv2UGMtWDs43xXaD4DUjuVMotKQ=";
      }
      else if pkgs.stdenv.hostPlatform.system == "aarch64-linux"
      then {
        asset = "moshi-hook_Linux_arm64.tar.gz";
        hash = "sha256-jE4559ZM6QJw209GAZYg+Th1KkM+mNvEPlTPJ6Kmi7c=";
      }
      else if pkgs.stdenv.hostPlatform.system == "x86_64-darwin"
      then {
        asset = "moshi-hook_Darwin_x86_64.tar.gz";
        hash = "sha256-JXO1pPKlBfiYhCGrvVPT33swEOOn/i1SemoYdPrMiPs=";
      }
      else if pkgs.stdenv.hostPlatform.system == "aarch64-darwin"
      then {
        asset = "moshi-hook_Darwin_arm64.tar.gz";
        hash = "sha256-ChQ34uBF5yquZenKvpZMxz4ZXYsl89VuA37RXAvnmeg=";
      }
      else throw "Unsupported platform for moshi-hook: ${pkgs.stdenv.hostPlatform.system}";
  in {
    packages.moshiHook = pkgs.stdenvNoCC.mkDerivation {
      pname = "moshi-hook";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://cdn.getmoshi.app/hook/v${version}/${platform.asset}";
        inherit (platform) hash;
      };

      nativeBuildInputs = [pkgs.gnutar];
      sourceRoot = ".";

      installPhase = ''
        runHook preInstall
        install -Dm755 moshi-hook "$out/bin/moshi-hook"
        ln -s moshi-hook "$out/bin/moshi"
        runHook postInstall
      '';

      meta = {
        description = "Portable daemon + CLI that bridges coding agents to the Moshi mobile app";
        homepage = "https://getmoshi.app";
        mainProgram = "moshi-hook";
        platforms = builtins.attrNames {
          x86_64-linux = null;
          aarch64-linux = null;
          x86_64-darwin = null;
          aarch64-darwin = null;
        };
      };
    };
  };

  flake.nixosModules.moshiHook = import ./moshi-hook.nix;
}
