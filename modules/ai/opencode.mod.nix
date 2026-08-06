{
  inputs,
  lib,
  self,
  ...
}: {
  flake.lib.opencode = {
    defaultSettings = pkgs: let
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
      share = "disabled";
      instructions = [
        "${pkgs.writeText "opencode-version-control.md" ''
          - Use `jj` for version control.
        ''}"
        "${self + /modules/ai/instructions.md}"
      ];
      permission = {
        bash =
          builtins.listToAttrs (map (command: {
              name = command;
              value = "allow";
            })
            readOnlyJjCommands)
          // {
            "git*" = "allow";
          };
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
        builtins.toJSON (
          {
            "$schema" = "https://opencode.ai/config.json";
          }
          // lib.recursiveUpdate (self.lib.opencode.defaultSettings pkgs) settings
        )
      );
  };

  perSystem = {pkgs, ...}: {
    packages.opencode = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
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

    upstreamOpencode = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
    mcpNixos = inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.mcp-nixos;
    exaKeyPath = lib.attrByPath ["sops" "secrets" "ai/exa-api-key" "path"] "/run/secrets/ai/exa-api-key" config;

    wrappedOpenCode = pkgs.writeShellScriptBin "opencode" ''
      export OPENCODE_CONFIG=${opencodeConfig}
      export OPENCODE_ENABLE_EXA=1
      if [ -r ${exaKeyPath} ]; then
        export EXA_API_KEY="$(cat ${exaKeyPath})"
      fi
      export PATH="${lib.makeBinPath [mcpNixos]}:$PATH"
      exec ${lib.getExe upstreamOpencode} "$@"
    '';
  in {
    imports = [self.nixosModules.sops];

    options.opencode = {
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

      settings = mkOption {
        type = types.attrs;
        default = {};
        description = "Settings merged into the generated OpenCode configuration.";
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

      environment.systemPackages =
        [wrappedOpenCode]
        ++ lib.optional (cfg.homelabServerUrl != null) (
          pkgs.writeShellScriptBin "opencode-homelab" ''
            exec ${lib.getExe wrappedOpenCode} attach ${cfg.homelabServerUrl} "$@"
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

      hjem.users.${config.userName}.rum.programs.fish.functions.homelab-code = lib.mkIf (hasHjemUsers && cfg.homelabServerUrl != null) ''
        opencode attach ${cfg.homelabServerUrl} $argv
      '';
    };
  };
}
