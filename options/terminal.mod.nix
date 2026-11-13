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

      # footclient: a window of the foot server (foot-server.socket), which
      # opens at once; -E gives its shell the environment it was started with.
      foot = {
        id = "foot";
        command = "uwsm app -- footclient -E";
        commandWithShell = "footclient -E";
        desktop = "foot.desktop";
        emulatorName = "foot";
        kdeApplication = "foot";
        openDirCommand = "footclient -E --working-directory %f";
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
