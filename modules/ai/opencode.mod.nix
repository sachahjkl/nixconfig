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
      animations = true;
      diffs.wrap = "word";
      plugins = ["${backlogPackage}/lib/opencode-backlog/dist/tui.js"];
      session = {
        scrollbar = false;
        sidebar = "auto";
        thinking = "hide";
      };
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

  perSystem = {pkgs, ...}: let
    opencode2 = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;
  in {
    packages.opencode = pkgs.symlinkJoin {
      name = "opencode";
      paths = [opencode2];
      postBuild = ''
        ln -sf ${lib.getExe opencode2} $out/bin/opencode
      '';
    };
  };

  flake.nixosModules.opencode = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    cfg = config.opencode;
    inherit (lib) mkEnableOption mkIf mkOption types;
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;

    opencodeConfig = self.lib.opencode.mkOpenCodeConfig {
      inherit pkgs;
      inherit (cfg) settings;
    };
    opencodeAgents = self.lib.opencode.mkOpenCodeAgents pkgs;
    opencodeCliConfig = self.lib.opencode.mkOpenCodeCliConfig {
      inherit pkgs;
      settings = cfg.cliSettings;
    };

    upstreamOpencode = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;
    mcpNixos = pkgs.mcp-nixos;
    exaKeyPath = lib.attrByPath ["sops" "secrets" "ai/exa-api-key" "path"] "/run/secrets/ai/exa-api-key" config;

    mkOpenCodeWrapper = name:
      pkgs.writeShellScriptBin name ''
        export OPENCODE_ENABLE_EXA=1
        if [ -r ${exaKeyPath} ]; then
          export EXA_API_KEY="$(cat ${exaKeyPath})"
        fi
        export PATH="${lib.makeBinPath [mcpNixos]}:$PATH"
        exec ${lib.getExe upstreamOpencode} "$@"
      '';

    wrappedOpenCode = pkgs.symlinkJoin {
      name = "opencode-wrapped";
      paths = [
        (mkOpenCodeWrapper "opencode")
        (mkOpenCodeWrapper "opencode2")
      ];
      meta.mainProgram = "opencode";
    };

    opencodeCompletions = pkgs.runCommand "opencode-completions" {} ''
      mkdir -p $out/share/fish/vendor_completions.d
      mkdir -p $out/share/bash-completion/completions
      mkdir -p $out/share/zsh/site-functions
      export HOME=$TMPDIR

      ${lib.getExe upstreamOpencode} --completions fish > $out/share/fish/vendor_completions.d/opencode2.fish
      ${lib.getExe upstreamOpencode} --completions bash > $out/share/bash-completion/completions/opencode2
      ${lib.getExe upstreamOpencode} --completions zsh > $out/share/zsh/site-functions/_opencode2

      sed 's/opencode2/opencode/g' $out/share/fish/vendor_completions.d/opencode2.fish > $out/share/fish/vendor_completions.d/opencode.fish
      sed 's/opencode2/opencode/g' $out/share/bash-completion/completions/opencode2 > $out/share/bash-completion/completions/opencode
      sed 's/opencode2/opencode/g' $out/share/zsh/site-functions/_opencode2 > $out/share/zsh/site-functions/_opencode
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
        description = "Whether to install and configure OpenCode.";
      };

      server = {
        enable = mkEnableOption "OpenCode headless API server";

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
        description = "URL of a remote OpenCode server to connect to via a shell function.";
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
      sops.secrets."ai/exa-api-key" = mkIf (config.sops.defaultSopsFile != null) {
        sopsFile = self + /secrets/shared.yaml;
        owner = config.userName;
        mode = "0400";
      };

      persist.user.directories = [
        ".config/opencode"
        ".local/share/opencode"
      ];

      hjem.users.${config.userName} = mkIf hasHjemUsers {
        files = {
          ".config/opencode/AGENTS.md".source = opencodeAgents;
          ".config/opencode/cli.json".source = opencodeCliConfig;
          ".config/opencode/opencode.json".source = opencodeConfig;
        };

        rum.programs.fish.functions.homelab-code = mkIf (cfg.homelabServerUrl != null) ''
          opencode --server ${cfg.homelabServerUrl} $argv
        '';
      };

      environment.systemPackages =
        [
          wrappedOpenCode
          opencodeCompletions
        ]
        ++ lib.optional (cfg.homelabServerUrl != null) (
          pkgs.writeShellScriptBin "opencode-homelab" ''
            exec ${lib.getExe wrappedOpenCode} --server ${cfg.homelabServerUrl} "$@"
          ''
        );

      systemd.services.opencode-server = mkIf cfg.server.enable {
        description = "OpenCode headless server";
        wantedBy = ["multi-user.target"];
        after = ["network-online.target"];
        requires = ["network-online.target"];
        serviceConfig = {
          Type = "simple";
          ExecStart = lib.escapeShellArgs [
            (lib.getExe wrappedOpenCode)
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
    };
  };
}
