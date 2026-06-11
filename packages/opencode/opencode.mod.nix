{
  inputs,
  lib,
  self,
  ...
}: {
  flake = {
    lib = {
      defaultOpenCodeSettings = pkgs: {
        autoupdate = false;
        share = "disabled";
        permission = {
          external_directory = {
            "/home/sacha/Projects/**" = "allow";
          };
          lsp = "allow";
          webfetch = "allow";
          websearch = "allow";
        };
        watcher.ignore = [
          ".direnv/**"
          ".git/**"
          "dist/**"
          "node_modules/**"
          "result/**"
        ];
        lsp.nix = {
          command = [(lib.getExe pkgs.nixd)];
          extensions = [".nix"];
        };
      };

      mkOpenCodeConfig = {
        pkgs,
        settings ? {},
      }:
        pkgs.writeText "opencode.json" (
          builtins.toJSON ({
              "$schema" = "https://opencode.ai/config.json";
            }
            // self.lib.defaultOpenCodeSettings pkgs // settings)
        );
    };

    wrappersModules.opencode = inputs.wrappers.lib.wrapModule (
      {
        config,
        lib,
        ...
      }: let
        configFile = config.pkgs.writeText "opencode.json" (
          builtins.toJSON ({
              "$schema" = "https://opencode.ai/config.json";
            }
            // self.lib.defaultOpenCodeSettings config.pkgs // config.settings)
        );
      in {
        options.settings = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = {};
        };

        config = {
          package = lib.mkDefault config.pkgs.opencode;
          env.OPENCODE_CONFIG = toString configFile;
          # https://opencode.ai/docs/tools/#websearch
          env.OPENCODE_ENABLE_EXA = "1";
        };
      }
    );

    nixosModules.opencode = {pkgs, ...}: let
      selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
    in {
      preferences.preservation.user.directories = [
        ".config/opencode"
        ".local/share/opencode"
      ];

      environment.systemPackages = [selfPkgs.opencode];
    };
  };

  perSystem = {pkgs, ...}: let
    version = "1.17.3";
    release =
      {
        x86_64-linux = {
          asset = "opencode-linux-x64.tar.gz";
          hash = "sha256-1L0jiiwf9WrKHNM5fSGgoxf1mSI0UXp/jir7vXIBCn0=";
        };
        aarch64-linux = {
          asset = "opencode-linux-arm64.tar.gz";
          hash = "sha256-hhuMZs7VHW2aZup3POR+3mY6RL0X2De5whrPo0aIAeU=";
        };
      }
      .${
        pkgs.stdenv.hostPlatform.system
      }
      or (throw "Unsupported opencode platform: ${pkgs.stdenv.hostPlatform.system}");
  in {
    packages.opencode-unwrapped = pkgs.stdenvNoCC.mkDerivation {
      pname = "opencode";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/anomalyco/opencode/releases/download/v${version}/${release.asset}";
        inherit (release) hash;
      };

      nativeBuildInputs = [
        pkgs.makeBinaryWrapper
        pkgs.patchelf
      ];

      unpackPhase = ''
        runHook preUnpack
        tar -xzf "$src"
        runHook postUnpack
      '';

      installPhase = ''
        runHook preInstall

        install -Dm755 opencode $out/bin/opencode
        patchelf \
          --set-interpreter "${pkgs.stdenv.cc.bintools.dynamicLinker}" \
          --set-rpath "${lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib]}" \
          $out/bin/opencode

        wrapProgram $out/bin/opencode \
          --prefix PATH : ${lib.makeBinPath [pkgs.ripgrep]}

        runHook postInstall
      '';

      doInstallCheck = true;
      nativeInstallCheckInputs = [pkgs.versionCheckHook];
      versionCheckProgramArg = "--version";

      meta = {
        description = "AI coding agent built for the terminal";
        homepage = "https://github.com/anomalyco/opencode";
        license = lib.licenses.mit;
        mainProgram = "opencode";
        platforms = ["x86_64-linux" "aarch64-linux"];
        sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      };
    };

    packages.opencode =
      (self.wrappersModules.opencode.apply {
        inherit pkgs;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.opencode-unwrapped;
        settings = {};
      }).wrapper;
  };
}
