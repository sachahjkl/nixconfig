{lib, ...}: {
  flake.nixosModules.thunar = {
    config,
    options,
    pkgs,
    ...
  }: let
    helpersRc = ''
      [Configuration]
      TerminalEmulator=${config.terminal.emulatorName}
      TerminalEmulatorDismissed=true
    '';

    ucaXml = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <actions>
      <action>
      	<icon>utilities-terminal</icon>
      	<name>Open Terminal Here</name>
      	<submenu></submenu>
      	<unique-id>1781344842619400-1</unique-id>
         <command>${config.terminal.openDirCommand}</command>
       	<description>Open a terminal in the selected directory</description>
      	<range></range>
      	<patterns>*</patterns>
      	<startup-notify/>
      	<directories/>
      </action>
      </actions>
    '';

    hasPersistUser = lib.hasAttrByPath ["persist" "user" "directories"] options;
    hasPreservation = hasPersistUser && config.persist.enable;

    persistentConfigDir = "${toString config.persist.persistentStoragePath}${config.homeDirectory}/.config";
    homeConfigDir = "${config.homeDirectory}/.config";
    configDir =
      if hasPreservation
      then persistentConfigDir
      else homeConfigDir;

    helpersTargetDir = "${configDir}/xfce4";
    helpersTargetFile = "${helpersTargetDir}/helpers.rc";

    thunarTargetDir = "${configDir}/Thunar";
    thunarTargetFile = "${thunarTargetDir}/uca.xml";
  in {
    config = lib.mkMerge [
      {
        programs = {
          # Thunar keeps its settings in xfconf.
          xfconf.enable = true;
          thunar = {
            enable = true;
            plugins = with pkgs; [
              thunar-archive-plugin
              thunar-media-tags-plugin
              thunar-volman
            ];
          };
        };

        # The file manager of every session but ShojiWM's, which has Classeur.
        xdg.mime.defaultApplications."inode/directory" = "thunar.desktop";

        system.activationScripts.thunarHelpers = lib.stringAfter ["users"] ''
          install -d -m 0755 -o ${config.userName} -g users ${helpersTargetDir}
          cat > ${helpersTargetFile} <<'EOF'
          ${helpersRc}
          EOF
          chown ${config.userName}:users ${helpersTargetFile}
          chmod 0644 ${helpersTargetFile}

          install -d -m 0755 -o ${config.userName} -g users ${thunarTargetDir}
          cat > ${thunarTargetFile} <<'EOF'
          ${ucaXml}
          EOF
          chown ${config.userName}:users ${thunarTargetFile}
          chmod 0644 ${thunarTargetFile}
        '';
      }

      (lib.optionalAttrs hasPersistUser {
        persist.user = lib.mkIf config.persist.enable {
          files = [
            ".config/xfce4/helpers.rc"
            ".config/Thunar/uca.xml"
          ];
          # Thunar's own settings (view, sort, side pane): xfconf writes them.
          directories = [".config/xfce4/xfconf"];
        };
      })
    ];
  };
}
