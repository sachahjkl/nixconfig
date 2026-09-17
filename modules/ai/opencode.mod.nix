{
  inputs,
  lib,
  self,
  ...
}: {
  flake.lib.opencode = {
    defaultSettings = homeDirectory: let
      extensionDirectory = "${homeDirectory}/.local/share/opencode/nix-extensions";
      readOnlyJjCommands = [
        "jj bookmark list*"
        "jj config get*"
        "jj config list*"
        "jj config path*"
        "jj diff*"
        "jj evolog*"
        "jj file annotate*"
        "jj file list*"
        "jj file search*"
        "jj file show*"
        "jj git colocation status*"
        "jj git remote list*"
        "jj git root*"
        "jj help*"
        "jj interdiff*"
        "jj log*"
        "jj op diff*"
        "jj op log*"
        "jj op show*"
        "jj operation diff*"
        "jj operation log*"
        "jj operation show*"
        "jj resolve --list"
        "jj root*"
        "jj show*"
        "jj sparse list*"
        "jj st*"
        "jj status*"
        "jj tag list*"
        "jj util completion*"
        "jj util config-schema*"
        "jj util markdown-help*"
        "jj version*"
        "jj workspace list*"
        "jj workspace root*"
      ];
    in {
      update = "disable";
      plugins = ["${extensionDirectory}/opencode-backlog.js"];
      providers.simulacra = {
        settings.apiKey = "unused";
        headers.X-Codex-Authorization = "Bearer {env:SIMULACRA_TOKEN}";
      };
      share = "disabled";
      skills = ["${extensionDirectory}/skills"];
      permissions =
        [
          {
            action = "shell";
            resource = "*";
            effect = "ask";
          }
        ]
        ++ map (command: {
          action = "shell";
          resource = command;
          effect = "allow";
        })
        readOnlyJjCommands
        ++ [
          {
            action = "shell";
            resource = "git*";
            effect = "allow";
          }
          {
            action = "external_directory";
            resource = "${homeDirectory}/Projects/*";
            effect = "allow";
          }
          {
            action = "webfetch";
            resource = "*";
            effect = "allow";
          }
          {
            action = "websearch";
            resource = "*";
            effect = "allow";
          }
          {
            action = "skill";
            resource = "*";
            effect = "allow";
          }
        ];
      watcher.ignore = [
        ".direnv/**"
        ".git/**"
        "dist/**"
        "node_modules/**"
        "result/**"
      ];
    };

    defaultCliSettings = homeDirectory: {
      "$schema" = "https://opencode.ai/v2/cli.json";
      attention.enabled = true;
      animations = true;
      debug = {
        devtools = true;
        turn_tokens = false;
      };
      diffs = {
        view = "split";
        wrap = "word";
      };
      plugins = ["${homeDirectory}/.local/share/opencode/nix-extensions/opencode-backlog-tui.js"];
      prompt.image_preview = true;
      scroll.acceleration = true;
      session = {
        image_preview = true;
        scrollbar = true;
        sidebar = "auto";
        thinking = "show";
      };
      tabs = {
        enabled = true;
        layout = "vertical";
        scope = "global";
        vertical = false;
      };
      terminal.copy = "manual";
      theme = {
        mode = "system";
        name = "opencode";
      };
    };

    mkOpenCodeAgents = pkgs:
      pkgs.writeText "AGENTS.md" ''
        ${builtins.readFile (self + /modules/ai/instructions.md)}

        ## Backlog

        Use the `backlog` tools to manage task stacks. Do not edit `BACKLOG.json` directly.

        - Run `backlog_list` before work to inspect the stack and obtain task IDs.
        - Run `backlog_add` to add a task.
        - Run `backlog_update` to change a task title or notes.
        - Run `backlog_move` to change a task state or position.
        - Run `backlog_remove` only when a task must be permanently removed.
        - Move active tasks to `doing`. Move completed tasks to `done`.
      '';

    mkOpenCodeConfig = {
      homeDirectory,
      pkgs,
      settings ? {},
    }:
      pkgs.writeText "opencode.json" (
        builtins.toJSON (
          {
            "$schema" = "https://opencode.ai/config.json";
          }
          // lib.recursiveUpdate (self.lib.opencode.defaultSettings homeDirectory) settings
        )
      );

    mkOpenCodeCliConfig = {
      homeDirectory,
      pkgs,
      settings ? {},
    }:
      pkgs.writeText "cli.json" (
        builtins.toJSON (lib.recursiveUpdate (self.lib.opencode.defaultCliSettings homeDirectory) settings)
      );
  };

  flake.nixosModules.opencode = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.opencode;
    inherit (lib) mkIf mkOption types;
    backlogPackage = inputs.opencode-backlog.packages.${pkgs.stdenv.hostPlatform.system}.default;
    extensionDirectory = "${config.homeDirectory}/.local/share/opencode/nix-extensions";
    simulacraTokenPath = "/run/secrets/ai/simulacra-token";

    opencodeConfig = self.lib.opencode.mkOpenCodeConfig {
      inherit (config) homeDirectory;
      inherit pkgs;
      settings = cfg.initialSettings;
    };
    opencodeAgents = self.lib.opencode.mkOpenCodeAgents pkgs;
    opencodeCliConfig = self.lib.opencode.mkOpenCodeCliConfig {
      inherit (config) homeDirectory;
      inherit pkgs;
      settings = cfg.initialCliSettings;
    };

    upstreamOpencode = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;
    mcpNixos = pkgs.mcp-nixos;

    mkOpenCodeWrapper = name:
      pkgs.writeShellScriptBin name ''
        export PATH="${lib.makeBinPath [mcpNixos]}:$PATH"
        export OPENCODE_MODELS_URL="https://codex.sacha.house"
        if [ -r ${simulacraTokenPath} ]; then
          export SIMULACRA_TOKEN="$(cat ${simulacraTokenPath})"
        fi
        exec ${lib.getExe upstreamOpencode} "$@"
      '';

    wrappedOpenCode = pkgs.symlinkJoin {
      name = "opencode2-wrapped";
      paths = [(mkOpenCodeWrapper "opencode2")];
      meta.mainProgram = "opencode2";
    };

    opencodeCompletions = pkgs.runCommand "opencode-completions" {} ''
      mkdir -p $out/share/fish/vendor_completions.d
      mkdir -p $out/share/bash-completion/completions
      mkdir -p $out/share/zsh/site-functions
      export HOME=$TMPDIR

      ${lib.getExe upstreamOpencode} --completions fish > $out/share/fish/vendor_completions.d/opencode2.fish
      ${lib.getExe upstreamOpencode} --completions bash > $out/share/bash-completion/completions/opencode2
      ${lib.getExe upstreamOpencode} --completions zsh > $out/share/zsh/site-functions/_opencode2
    '';
  in {
    imports = [
      self.nixosModules.sops
      self.nixosModules.skills
    ];

    options.opencode = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to initialize writable OpenCode configuration files.";
      };

      initialSettings = mkOption {
        type = types.attrs;
        default = {};
        description = "Settings used only when the writable OpenCode configuration is first created.";
      };

      initialCliSettings = mkOption {
        type = types.attrs;
        default = {};
        description = "Settings used only when the writable OpenCode CLI configuration is first created.";
      };
    };

    config = mkIf cfg.enable {
      sops.secrets = mkIf (config.sops.defaultSopsFile != null) {
        "ai/simulacra-token" = {
          sopsFile = builtins.path {
            path = self + /secrets/shared.yaml;
            name = "shared-secrets.yaml";
          };
          owner = config.userName;
          mode = "0400";
          path = simulacraTokenPath;
        };
      };

      persist.user.directories = [
        ".config/opencode"
        ".local/share/opencode"
      ];

      environment = {
        extraInit = ''
          if [ -r ${simulacraTokenPath} ]; then
            export SIMULACRA_TOKEN="$(cat ${simulacraTokenPath})"
          fi
        '';
        sessionVariables.OPENCODE_MODELS_URL = "https://codex.sacha.house";
        systemPackages = [wrappedOpenCode opencodeCompletions];
      };

      hjem.users.${config.userName} = {
        environment.sessionVariables.OPENCODE_MODELS_URL = "https://codex.sacha.house";
        files.".config/fish/conf.d/opencode.fish".text = ''
          set --global --export OPENCODE_MODELS_URL https://codex.sacha.house
          if test -r ${simulacraTokenPath}
            set --global --export SIMULACRA_TOKEN (string collect <${simulacraTokenPath})
          end
        '';
      };

      systemd.user.tmpfiles.users.${config.userName}.rules = [
        "d ${config.homeDirectory}/.config/opencode 0700 - - -"
        "d ${extensionDirectory} 0700 - - -"
        "C ${config.homeDirectory}/.config/opencode/AGENTS.md 0644 - - - ${opencodeAgents}"
        "C ${config.homeDirectory}/.config/opencode/cli.json 0644 - - - ${opencodeCliConfig}"
        "C ${config.homeDirectory}/.config/opencode/opencode.json 0644 - - - ${opencodeConfig}"
        "L+ ${extensionDirectory}/opencode-backlog.js - - - - ${backlogPackage}/lib/opencode-backlog/dist/index.js"
        "L+ ${extensionDirectory}/opencode-backlog-tui.js - - - - ${backlogPackage}/lib/opencode-backlog/dist/tui.js"
        "L+ ${extensionDirectory}/skills - - - - ${inputs.skills}"
      ];
    };
  };
}
