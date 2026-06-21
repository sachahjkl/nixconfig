{lib, ...}: {
  flake.nixosModules.thunar = {config, ...}: let
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

    hasPreservation =
      lib.hasAttrByPath ["persist" "enable"] config
      && config.persist.enable;

    persistentConfigDir = "${toString config.persist.persistentStoragePath}/home/${config.userName}/.config";
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
    persist.user.files = lib.mkIf hasPreservation [
      ".config/xfce4/helpers.rc"
      ".config/Thunar/uca.xml"
    ];

    system.activationScripts.thunarHelpers.text = ''
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
  };
}
