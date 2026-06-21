{self, ...}: {
  flake.nixosModules.terminal = {
    config,
    lib,
    pkgs,
    ...
  }: let
    terminalNames = builtins.attrNames self.lib.terminals;
    terminalConfigType = lib.types.submodule ({name, ...}: {
      options = {
        enable = lib.mkEnableOption "${name} terminal";

        theme = lib.mkOption {
          type = lib.types.attrs;
          default = self.lib.terminalThemes.kittyDefault;
          description = "Theme palette for ${name}.";
        };
        };
      });
    xtermCompatWrapper = pkgs.writeShellScriptBin "xterm-${config.terminal.emulatorName}" ''
      exec ${config.terminal.command} "$@"
    '';
  in {
    options.terminal = lib.mkOption {
      type = lib.types.submodule ({config, ...}: {
        freeformType = lib.types.attrsOf terminalConfigType;

        options = {
          default = lib.mkOption {
            type = lib.types.enum terminalNames;
            default = "kitty";
            description = "Which terminal emulator to use as the system default.";
          };

          id = lib.mkOption {
            type = lib.types.str;
            description = "Terminal identifier.";
            internal = true;
          };

          command = lib.mkOption {
            type = lib.types.str;
            description = "Command used to open a new terminal window.";
            internal = true;
          };

          commandWithShell = lib.mkOption {
            type = lib.types.str;
            description = "Command used to run a shell command in the terminal.";
            internal = true;
          };

          desktop = lib.mkOption {
            type = lib.types.str;
            description = "Desktop entry used by xdg-terminal-exec.";
            internal = true;
          };

          emulatorName = lib.mkOption {
            type = lib.types.str;
            description = "Terminal emulator program name.";
            internal = true;
          };

          kdeApplication = lib.mkOption {
            type = lib.types.str;
            description = "KDE terminal application name.";
            internal = true;
          };

          openDirCommand = lib.mkOption {
            type = lib.types.str;
            description = "Command used to open a terminal in a directory.";
            internal = true;
          };
        };

        config = let
          terminal = self.lib.terminals.${config.default};
        in
          {
            # Materialize every terminal subtree so per-terminal defaults exist
            # even before a host explicitly configures them.
          }
          // lib.genAttrs terminalNames (_: {})
          // {
            inherit
              (terminal)
              id
              command
              commandWithShell
              desktop
              emulatorName
              kdeApplication
              openDirCommand
              ;
          };
      });
      description = "Shared terminal interface used by desktop integrations.";
    };

    config.environment.systemPackages = [xtermCompatWrapper];
  };
}
