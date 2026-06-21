{self, ...}: {
  flake.nixosModules.editor = {lib, ...}: let
    editorNames = builtins.attrNames self.lib.editors;
    editorConfigType = lib.types.submodule ({name, ...}: {
      options.enable = lib.mkEnableOption "${name} editor";
    });
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
          terminalCommand = lib.attrByPath ["terminal" "commandWithShell"] null config;
          wrap = command:
            if editor.needsTerminal && terminalCommand != null
            then "${terminalCommand} ${command}"
            else command;
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
            launchCommand = wrap editor.command;
            launchCommandWithFile = wrap editor.commandWithFile;
            launchCommandWithLocation = wrap editor.commandWithLocation;
          };
      });
      description = "Shared editor interface used by shells and desktop integrations.";
    };
  };
}
