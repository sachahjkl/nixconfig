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

    nixosModules.opencode = {
      config,
      lib,
      options,
      pkgs,
      ...
    }: let
      selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
      cfg = config.preferences.opencode;
      inherit (lib) mkEnableOption mkIf mkOption types;
      hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
    in {
      options.preferences.opencode = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to install and configure OpenCode.";
        };

        server = {
          enable = mkEnableOption "OpenCode headless server";

          hostname = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = "Hostname the OpenCode server listens on.";
          };

          port = mkOption {
            type = types.port;
            default = 4096;
            description = "Port the OpenCode server listens on.";
          };

          openFirewall = mkOption {
            type = types.bool;
            default = true;
            description = "Open the firewall for the OpenCode server port.";
          };
        };

        homelabServerUrl = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "URL of a remote OpenCode server to attach to via a shell function.";
        };
      };

      config = mkIf cfg.enable {
        preferences.preservation.user.directories = [
          ".config/opencode"
          ".local/share/opencode"
        ];

        environment.systemPackages = [selfPkgs.opencode];

        systemd.services.opencode-server = mkIf cfg.server.enable {
          description = "OpenCode headless server";
          wantedBy = ["multi-user.target"];
          after = ["network-online.target"];
          requires = ["network-online.target"];
          serviceConfig = {
            Type = "simple";
            ExecStart = lib.escapeShellArgs [
              (lib.getExe selfPkgs.opencode)
              "serve"
              "--hostname"
              cfg.server.hostname
              "--port"
              (toString cfg.server.port)
            ];
            Restart = "on-failure";
            User = config.userName;
            Group = "users";
          };
        };

        networking.firewall.allowedTCPPorts = mkIf (cfg.server.enable && cfg.server.openFirewall) [cfg.server.port];
        hjem.users.${config.userName}.rum.programs.fish.functions.homelab-code = lib.mkIf (hasHjemUsers && cfg.homelabServerUrl != null) ''
          opencode attach ${cfg.homelabServerUrl} $argv
        '';
      };
    };
  };

  perSystem = {
    pkgs,
    self',
    ...
  }: let
    version = "1.17.7";
    release =
      {
        x86_64-linux = {
          asset = "opencode-linux-x64.tar.gz";
          hash = "sha256-YP5aktya9k7AeTSP7d4X4S2mqGfv5+g1O+gDhIBgeSQ=";
        };
        aarch64-linux = {
          asset = "opencode-linux-arm64.tar.gz";
          hash = "sha256-rIDqDufj8QSDvZgphlS2qt3DBciAsWJmegPnQtmEP+Y=";
        };
      }
      .${
        pkgs.stdenv.hostPlatform.system
      }
      or (throw "Unsupported opencode platform: ${pkgs.stdenv.hostPlatform.system}");
  in {
    packages = {
      opencode-unwrapped = pkgs.stdenvNoCC.mkDerivation {
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
            --prefix PATH : ${lib.makeBinPath [pkgs.ripgrep self'.packages.mcp-nixos]}

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

      opencode =
        (self.wrappersModules.opencode.apply {
          inherit pkgs;
          package = self.packages.${pkgs.stdenv.hostPlatform.system}.opencode-unwrapped;
          settings = {};
        }).wrapper;

      mcp-nixos = inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.mcp-nixos;
    };
  };
}
