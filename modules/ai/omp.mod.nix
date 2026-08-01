{self, ...}: {
  flake.nixosModules.omp = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    cfg = config.ai.omp;
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
    selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};

    upstreamOmp = selfPkgs.omp;
    exaKeyPath = lib.attrByPath ["sops" "secrets" "ai/exa-api-key" "path"] "/run/secrets/ai/exa-api-key" config;
    opencodeKeyPath = lib.attrByPath ["sops" "secrets" "ai/opencode-api-key" "path"] "/run/secrets/ai/opencode-api-key" config;

    wrappedOmp = pkgs.writeShellScriptBin "omp" ''
      if [ -r ${exaKeyPath} ]; then
        export EXA_API_KEY="$(cat ${exaKeyPath})"
      fi
      if [ -r ${opencodeKeyPath} ]; then
        export OPENCODE_API_KEY="$(cat ${opencodeKeyPath})"
      fi
      exec ${lib.getExe upstreamOmp} "$@"
    '';

    ompConfig = pkgs.writeText "omp-config.yml" (lib.generators.toYAML {} {
      theme = {
        dark = "titanium";
        light = "light";
      };

      symbolPreset = "nerd";

      statusLine = {
        separator = "slash";
        transparent = true;
        showHookStatus = true;
      };

      tui = {
        textSizing = true;
      };

      display = {
        shimmer = "kitt";
      };

      startup = {
        setupWizard = false;
      };

      memory = {
        backend = "mnemopi";
      };

      tools = {
        discoveryMode = "all";
        essentialOverride = [];
      };

      mcp = {
        discoveryMode = "all";
        discoveryDefaultServers = [];
      };

      render_mermaid = {
        enabled = true;
      };

      tts = {
        enabled = true;
      };

      inspect_image = {
        enabled = true;
      };

      checkpoint = {
        enabled = true;
      };

      github = {
        enabled = true;
        cache = {
          enabled = true;
        };
      };

      terminal = {
        showImages = true;
      };

      images = {
        autoResize = true;
      };

      compaction = {
        enabled = true;
        strategy = "context-full";
        autoContinue = true;
      };

      mnemopi = {
        retainEveryNTurns = 4;
        recallLimit = 8;
        recallContextTurns = 3;
      };
    });

    ompModels = pkgs.writeText "omp-models.yml" (lib.generators.toYAML {} {
      providers = {
        opencode-go = {
          baseUrl = "https://opencode.ai/zen/go/v1";
          apiKey = "OPENCODE_API_KEY";
          api = "openai-completions";
          authHeader = true;
        };
      };
    });

    ompCompletions =
      pkgs.runCommand "omp-completions" {
        nativeBuildInputs = [wrappedOmp];
      } ''
        mkdir -p $out/share/fish/vendor_completions.d
        mkdir -p $out/share/bash-completion/completions
        mkdir -p $out/share/zsh/site-functions
        HOME=$TMPDIR omp completions fish > $out/share/fish/vendor_completions.d/omp.fish
        HOME=$TMPDIR omp completions bash > $out/share/bash-completion/completions/omp
        HOME=$TMPDIR omp completions zsh > $out/share/zsh/site-functions/_omp
      '';
  in {
    imports = [self.nixosModules.sops];

    options.ai.omp.enable = lib.mkEnableOption "Oh My Pi terminal coding agent";

    config = lib.mkIf cfg.enable {
      sops.secrets = lib.mkIf (config.sops.defaultSopsFile != null) {
        "ai/exa-api-key" = {
          sopsFile = self + /secrets/shared.yaml;
          owner = config.userName;
          mode = "0400";
        };

        "ai/opencode-api-key" = {
          sopsFile = self + /secrets/shared.yaml;
          owner = config.userName;
          mode = "0400";
        };
      };

      environment.systemPackages = [
        wrappedOmp
        ompCompletions
      ];

      persist.user.directories = [
        ".omp"
      ];

      hjem.users.${config.userName} = lib.mkIf hasHjemUsers {
        files = {
          ".omp/agent/config.yml".source = ompConfig;
          ".omp/agent/AGENTS.md".source = self + /modules/ai/instructions.md;
          ".omp/agent/models.yml".source = ompModels;
        };
      };
    };
  };
}
