{self, ...}: {
  flake.nixosModules.editor = {
    config,
    lib,
    pkgs,
    ...
  }: let
    editorNames = builtins.attrNames self.lib.editors;
    terminalCommand = lib.attrByPath ["terminal" "commandWithShell"] null config;
    editorConfigType = lib.types.submodule ({name, ...}: {
      options.enable = lib.mkEnableOption "${name} editor";
    });
    wrapEditorCommand = editor: command:
      if editor.needsTerminal && terminalCommand != null
      then "${terminalCommand} ${command}"
      else command;
    editorLaunchers = builtins.map (
      name: let
        editor = self.lib.editors.${name};
      in
        pkgs.writeShellScriptBin "${name}-editor" ''
          exec ${wrapEditorCommand editor editor.commandWithFile} "$@"
        ''
    ) editorNames;
  in {
    options.editor = lib.mkOption {
      type = lib.types.submodule ({config, ...}: {
        freeformType = lib.types.attrsOf editorConfigType;

        options = {
          default = lib.mkOption {
            type = lib.types.enum editorNames;
            default = "neovim";
            description = "Which editor to use as the system default.";
          };

          id = lib.mkOption {
            type = lib.types.str;
            internal = true;
          };
          command = lib.mkOption {
            type = lib.types.str;
            internal = true;
          };
          commandWithFile = lib.mkOption {
            type = lib.types.str;
            internal = true;
          };
          commandWithLine = lib.mkOption {
            type = lib.types.str;
            internal = true;
          };
          commandWithLocation = lib.mkOption {
            type = lib.types.str;
            internal = true;
          };
          watchCommand = lib.mkOption {
            type = lib.types.str;
            internal = true;
          };
          launchCommand = lib.mkOption {
            type = lib.types.str;
            internal = true;
          };
          launchCommandWithFile = lib.mkOption {
            type = lib.types.str;
            internal = true;
          };
          launchCommandWithLocation = lib.mkOption {
            type = lib.types.str;
            internal = true;
          };
          desktop = lib.mkOption {
            type = lib.types.str;
            internal = true;
          };
          icon = lib.mkOption {
            type = lib.types.str;
            internal = true;
          };
          needsTerminal = lib.mkOption {
            type = lib.types.bool;
            internal = true;
          };
        };

        config = let
          editor = self.lib.editors.${config.default};
        in
          lib.genAttrs editorNames (_: {})
          // {
            inherit (editor) id desktop icon needsTerminal;
            inherit
              (editor)
              command
              commandWithFile
              commandWithLine
              commandWithLocation
              watchCommand
              ;
            launchCommand = wrapEditorCommand editor editor.command;
            launchCommandWithFile = wrapEditorCommand editor editor.commandWithFile;
            launchCommandWithLocation = wrapEditorCommand editor editor.commandWithLocation;
          };
      });
      description = "Shared editor interface used by shells and desktop integrations.";
    };

    config.environment.systemPackages = editorLaunchers ++ [
      (pkgs.writeShellScriptBin "default-editor" ''
        exec ${config.editor.id}-editor "$@"
      '')
    ];
  };
}
