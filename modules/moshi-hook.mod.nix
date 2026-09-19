_: {
  perSystem = {pkgs, ...}: let
    version = "0.3.25";
    platform =
      if pkgs.stdenv.hostPlatform.system == "x86_64-linux"
      then {
        asset = "moshi-hook_Linux_x86_64.tar.gz";
        hash = "sha256-qQkFJQrco7Vqxrtw7E5SmPvNiQSlCg+kwWz0ODptYH8=";
      }
      else if pkgs.stdenv.hostPlatform.system == "aarch64-linux"
      then {
        asset = "moshi-hook_Linux_arm64.tar.gz";
        hash = "sha256-iMMF6UzNCxQKNT8MwK2gN6vHT/tDyH7bSJqU2WibqWc=";
      }
      else if pkgs.stdenv.hostPlatform.system == "x86_64-darwin"
      then {
        asset = "moshi-hook_Darwin_x86_64.tar.gz";
        hash = "sha256-d2vcH9xug4AlI0BADBwaihhCIJ95iNBx6VrhZUSeEMA=";
      }
      else if pkgs.stdenv.hostPlatform.system == "aarch64-darwin"
      then {
        asset = "moshi-hook_Darwin_arm64.tar.gz";
        hash = "sha256-bWj50OPgxhfiuVyo+8W5Xc3eVQe2KKBqbmUEi6gHfgc=";
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

    checks.moshi-hook =
      pkgs.runCommand "moshi-hook-tests" {
        nativeBuildInputs = [pkgs.bun];
      } ''
        export HOME="$TMPDIR"
        bun test ${./ai/plugins}/moshi-hooks.test.ts
        touch "$out"
      '';
  };

  flake.nixosModules.moshiHook = import ./moshi-hook.nix;
}
