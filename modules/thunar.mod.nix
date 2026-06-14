{lib, ...}: {
  flake.nixosModules.thunar = {config, ...}: let
    helpersRc = ''
      [Configuration]
      TerminalEmulator=kitty
      TerminalEmulatorDismissed=true
    '';

    hasPreservation =
      lib.hasAttrByPath ["preferences" "preservation" "enable"] config
      && config.preferences.preservation.enable;

    targetDir =
      if hasPreservation
      then "${toString config.preferences.preservation.persistentStoragePath}/home/${config.userName}/.config/xfce4"
      else "${config.homeDirectory}/.config/xfce4";

    targetFile = "${targetDir}/helpers.rc";
  in {
    preferences.preservation.user.files = lib.mkIf hasPreservation [
      ".config/xfce4/helpers.rc"
    ];

    system.activationScripts.thunarHelpers.text = ''
      install -d -m 0755 -o ${config.userName} -g users ${targetDir}
      cat > ${targetFile} <<'EOF'
      ${helpersRc}
      EOF
      chown ${config.userName}:users ${targetFile}
      chmod 0644 ${targetFile}
    '';
  };
}
