{
  inputs,
  lib,
  self,
  ...
}: {
  flake.lib.opencode = {
    defaultSettings = homeDirectory: let
      extensionDirectory = "${homeDirectory}/.local/share/opencode/nix-extensions";
    in {
      update = "disable";
      share = "disabled";
      skills = ["${extensionDirectory}/skills"];
      # The last matching rule wins. Allow shell commands, and ask before
      # commands that delete data, discard Git work, or change the system.
      permissions =
        [
          {
            action = "shell";
            resource = "*";
            effect = "allow";
          }
        ]
        ++ map (resource: {
          action = "shell";
          inherit resource;
          effect = "ask";
        }) [
          "rm *"
          "sudo *"
          "dd *"
          "mkfs*"
          "shutdown *"
          "reboot *"
          "poweroff *"
          "systemctl poweroff *"
          "systemctl reboot *"
          "git reset --hard*"
          "git clean *"
          "git push --force*"
          "git push -f*"
        ]
        ++ [
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

    defaultCliSettings = _: {
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
      pkgs.writeText "AGENTS.md" (builtins.readFile (self + /modules/ai/instructions.md));

    mkOpenCodeConfig = {
      homeDirectory,
      pkgs,
      settings ? {},
    }:
      pkgs.writeText "opencode-managed.json" (
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
    inherit (lib) mkEnableOption mkIf mkOption types;
    extensionDirectory = "${config.homeDirectory}/.local/share/opencode/nix-extensions";

    opencodeConfig = self.lib.opencode.mkOpenCodeConfig {
      inherit (config) homeDirectory;
      inherit pkgs;
      inherit (cfg) settings;
    };
    opencodeAgents = self.lib.opencode.mkOpenCodeAgents pkgs;
    opencodeCliConfig = self.lib.opencode.mkOpenCodeCliConfig {
      inherit (config) homeDirectory;
      inherit pkgs;
      settings = cfg.initialCliSettings;
    };

    upstreamOpencode = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;
    mcpNixos = pkgs.mcp-nixos;

    opencodeWrapper = pkgs.writeShellScriptBin "opencode" ''
      export PATH="${lib.makeBinPath [mcpNixos]}:$PATH"
      exec ${lib.getExe upstreamOpencode} "$@"
    '';

    wrappedOpenCode = pkgs.symlinkJoin {
      name = "opencode-wrapped";
      paths = [opencodeWrapper];
      postBuild = ''
        ln -s opencode $out/bin/opencode2
      '';
      meta.mainProgram = "opencode";
    };

    opencodeServer = pkgs.writeShellScript "opencode-server" ''
      set -eu
      export OPENCODE_SERVER_PASSWORD="$(cat "$CREDENTIALS_DIRECTORY/password")"
      exec ${lib.getExe wrappedOpenCode} serve \
        --hostname ${lib.escapeShellArg cfg.server.hostname} \
        --port ${toString cfg.server.port} \
        ${lib.concatMapStringsSep " " (origin: "--cors ${lib.escapeShellArg origin}") cfg.server.cors}
    '';

    opencodeCompletions = pkgs.runCommand "opencode-completions" {} ''
      mkdir -p $out/share/fish/vendor_completions.d
      mkdir -p $out/share/bash-completion/completions
      mkdir -p $out/share/zsh/site-functions
      export HOME=$TMPDIR

      ${lib.getExe upstreamOpencode} --completions fish > $out/share/fish/vendor_completions.d/opencode.fish
      ${lib.getExe upstreamOpencode} --completions bash > $out/share/bash-completion/completions/opencode
      ${lib.getExe upstreamOpencode} --completions zsh > $out/share/zsh/site-functions/_opencode

      sed 's/opencode/opencode2/g' $out/share/fish/vendor_completions.d/opencode.fish \
        > $out/share/fish/vendor_completions.d/opencode2.fish
      sed 's/opencode/opencode2/g' $out/share/bash-completion/completions/opencode \
        > $out/share/bash-completion/completions/opencode2
      sed 's/opencode/opencode2/g' $out/share/zsh/site-functions/_opencode \
        > $out/share/zsh/site-functions/_opencode2
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

      settings = mkOption {
        type = types.attrs;
        default = {};
        description = "Settings merged into opencode.jsonc at each activation. They replace the same keys in the file and keep the other keys.";
      };

      initialCliSettings = mkOption {
        type = types.attrs;
        default = {};
        description = "Settings used only when the writable OpenCode CLI configuration is first created.";
      };

      session.enable = mkEnableOption "the OpenCode server (opencode2 serve --service) as a service of the user's graphical session";

      server = {
        enable = mkEnableOption "OpenCode API and web server";

        hostname = mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = "Address on which the OpenCode server listens.";
        };

        port = mkOption {
          type = types.port;
          default = 4096;
          description = "Port on which the OpenCode server listens.";
        };

        passwordFile = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "File containing the OpenCode server password.";
        };

        cors = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Browser origins allowed to call the OpenCode server.";
        };
      };
    };

    config = mkIf cfg.enable {
      persist.user.directories = [
        ".config/opencode"
        ".local/share/opencode"
        # the browse MCP server (opencode.jsonc: ~/.local/bin/browse mcp), which updates itself there
        ".local/bin"
      ];

      environment = {
        systemPackages = [wrappedOpenCode opencodeCompletions];
      };

      # Merge the Nix settings into opencode.jsonc at each activation.
      # Nix settings replace the same keys. Other keys in the file stay.
      system.userActivationScripts.opencodeConfig = ''
        if [ "$HOME" = ${lib.escapeShellArg config.homeDirectory} ]; then
          opencodeConfigFile="$HOME/.config/opencode/opencode.jsonc"
          mkdir -p "$HOME/.config/opencode"
          if [ ! -e "$opencodeConfigFile" ]; then
            ${lib.getExe pkgs.jq} . ${opencodeConfig} > "$opencodeConfigFile"
          elif ${lib.getExe pkgs.jq} --slurpfile managed ${opencodeConfig} '. * $managed[0]' \
            "$opencodeConfigFile" > "$opencodeConfigFile.tmp"; then
            mv "$opencodeConfigFile.tmp" "$opencodeConfigFile"
          else
            rm -f "$opencodeConfigFile.tmp"
            echo "warning: cannot read $opencodeConfigFile as JSON (comments?). The Nix OpenCode settings were not applied." >&2
          fi
        fi
      '';

      assertions = [
        {
          assertion = !cfg.server.enable || cfg.server.passwordFile != null;
          message = "opencode.server.passwordFile must be set when the OpenCode server is enabled.";
        }
      ];

      systemd = {
        user.tmpfiles.users.${config.userName}.rules = [
          "d ${config.homeDirectory}/.config/opencode 0700 - - -"
          "d ${extensionDirectory} 0700 - - -"
          "C ${config.homeDirectory}/.config/opencode/AGENTS.md 0644 - - - ${opencodeAgents}"
          "C ${config.homeDirectory}/.config/opencode/cli.json 0644 - - - ${opencodeCliConfig}"
          "L+ ${extensionDirectory}/skills - - - - ${inputs.skills}"
        ];

        # The server the OpenCode apps and terminals attach to, started with the session rather
        # than by hand from a terminal.
        user.services.opencode = mkIf cfg.session.enable {
          description = "OpenCode server of the user's session";
          wantedBy = ["graphical-session.target"];
          after = ["graphical-session.target"];
          # It runs the agents' sessions: a system switch must not cut them. A new version runs
          # from the next login, or after `systemctl --user restart opencode`.
          restartIfChanged = false;
          serviceConfig = {
            # Through the login shell: the programs and environment of a server started from a
            # terminal (the session's PATH, the user's profiles), which the agents' tools need.
            ExecStart = "${lib.getExe config.users.users.${config.userName}.shell} -l -c ${lib.escapeShellArg "exec ${lib.getExe wrappedOpenCode} serve --service"}";
            WorkingDirectory = "%h";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };

        services.opencode = mkIf cfg.server.enable {
          description = "OpenCode API and web server";
          wantedBy = ["multi-user.target"];
          after = ["network-online.target"];
          wants = ["network-online.target"];
          environment = {
            HOME = config.homeDirectory;
          };
          serviceConfig = {
            User = config.userName;
            Group = "users";
            WorkingDirectory = config.homeDirectory;
            ExecStart = opencodeServer;
            LoadCredential = "password:${cfg.server.passwordFile}";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      };
    };
  };
}
