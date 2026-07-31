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
