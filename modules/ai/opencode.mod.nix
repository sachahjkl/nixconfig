{
  inputs,
  lib,
  self,
  ...
}: {
  flake.lib.opencode = {
    defaultSettings = pkgs: let
      backlogPackage = inputs.opencode-backlog.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
      autoupdate = false;
      plugins = ["${backlogPackage}/lib/opencode-backlog/dist/index.js"];
      providers.simulacra = {
        settings.apiKey = "unused";
        headers.X-Codex-Authorization = "Bearer {env:SIMULACRA_TOKEN}";
      };
      share = "disabled";
      skills = ["${inputs.skills}"];
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
            resource = "/home/sacha/Projects/*";
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
      lsp.nix = {
        command = [(lib.getExe pkgs.nixd)];
        extensions = [".nix"];
      };
    };

    defaultCliSettings = pkgs: let
      backlogPackage = inputs.opencode-backlog.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in {
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
      plugins = ["${backlogPackage}/lib/opencode-backlog/dist/tui.js"];
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
      pkgs,
      settings ? {},
    }:
      pkgs.writeText "opencode.json" (
        builtins.toJSON (
          {
            "$schema" = "https://opencode.ai/config.json";
          }
          // lib.recursiveUpdate (self.lib.opencode.defaultSettings pkgs) settings
        )
      );

    mkOpenCodeCliConfig = {
      pkgs,
      settings ? {},
    }:
      pkgs.writeText "cli.json" (
        builtins.toJSON (lib.recursiveUpdate (self.lib.opencode.defaultCliSettings pkgs) settings)
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

    opencodeConfig = self.lib.opencode.mkOpenCodeConfig {
      inherit pkgs;
      inherit (cfg) settings;
    };
    opencodeAgents = self.lib.opencode.mkOpenCodeAgents pkgs;
    opencodeCliConfig = self.lib.opencode.mkOpenCodeCliConfig {
      inherit pkgs;
      settings = cfg.cliSettings;
    };
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

      settings = mkOption {
        type = types.attrs;
        default = {};
        description = "Settings merged into the generated OpenCode configuration.";
      };

      cliSettings = mkOption {
        type = types.attrs;
        default = {};
        description = "Settings merged into the generated OpenCode TUI configuration.";
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
        };
      };

      persist.user.directories = [
        ".config/opencode"
        ".local/share/opencode"
      ];

      systemd.services.opencode-config = {
        description = "Initialize writable OpenCode configuration files";
        wantedBy = ["multi-user.target"];
        after = ["hjem.target"];
        requires = ["hjem.target"];
        restartTriggers = [opencodeAgents opencodeCliConfig opencodeConfig];
        serviceConfig = {
          Type = "oneshot";
          User = config.userName;
          Group = "users";
        };
        script = ''
          config_directory=${lib.escapeShellArg "${config.homeDirectory}/.config/opencode"}
          mkdir -p "$config_directory"

          initialize_config() {
            source="$1"
            target="$2"

            if [ ! -e "$target" ]; then
              install -m 0644 "$source" "$target"
            fi
          }

          initialize_config ${opencodeAgents} "$config_directory/AGENTS.md"
          initialize_config ${opencodeCliConfig} "$config_directory/cli.json"
          initialize_config ${opencodeConfig} "$config_directory/opencode.json"
        '';
      };
    };
  };
}
