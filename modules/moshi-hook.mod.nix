_: {
  perSystem = {pkgs, ...}: let
    version = "0.3.19";
    platform =
      if pkgs.stdenv.hostPlatform.system == "x86_64-linux"
      then {
        asset = "moshi-hook_Linux_x86_64.tar.gz";
        hash = "sha256-yUzj3luOe20bnxLVAaldsEfwG/Mra4N+KaQikmfuedQ=";
      }
      else if pkgs.stdenv.hostPlatform.system == "aarch64-linux"
      then {
        asset = "moshi-hook_Linux_arm64.tar.gz";
        hash = "sha256-EsBimaR3DwrYEl6VzUnMb3EtGK4SMIr50iUIWbZ6e44=";
      }
      else if pkgs.stdenv.hostPlatform.system == "x86_64-darwin"
      then {
        asset = "moshi-hook_Darwin_x86_64.tar.gz";
        hash = "sha256-H1PFHcU6X3yF5mLHQliDslEpW0KBmGYv8EVq0WoV9pI=";
      }
      else if pkgs.stdenv.hostPlatform.system == "aarch64-darwin"
      then {
        asset = "moshi-hook_Darwin_arm64.tar.gz";
        hash = "sha256-va7rARMp56XK/8+cF2kG957n3Lo7ghd0Ouicz7euR3M=";
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
