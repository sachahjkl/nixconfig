{
  config.flake.lib = {
    terminals = {
      ghostty = {
        id = "ghostty";
        command = "uwsm app -- ghostty +new-window";
        commandWithShell = "uwsm app -- ghostty +new-window -e";
        desktop = "ghostty.desktop";
        emulatorName = "ghostty";
        kdeApplication = "ghostty";
        openDirCommand = "uwsm app -- ghostty +new-window --working-directory %f";
        scratchpadClass = "dropdown.ghostty";
      };

      foot = {
        id = "foot";
        command = "uwsm app -- foot";
        commandWithShell = "foot";
        desktop = "foot.desktop";
        emulatorName = "foot";
        kdeApplication = "foot";
        openDirCommand = "foot --working-directory %f";
        scratchpadClass = "dropdown.foot";
      };

      kitty = {
        id = "kitty";
        command = "uwsm app -- kitty";
        commandWithShell = "kitty -e";
        desktop = "kitty.desktop";
        emulatorName = "kitty";
        kdeApplication = "kitty";
        openDirCommand = "kitty --directory %f";
        scratchpadClass = "dropdown.kitty";
      };
    };
  };
}
