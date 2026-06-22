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

    terminalThemes = {
      campbell = {
        name = "Campbell";
        background = "#0C0C0C";
        black = "#0C0C0C";
        blue = "#0037DA";
        brightBlack = "#767676";
        brightBlue = "#3B78FF";
        brightCyan = "#61D6D6";
        brightGreen = "#16C60C";
        brightPurple = "#B4009E";
        brightRed = "#E74856";
        brightWhite = "#F2F2F2";
        brightYellow = "#F9F1A5";
        cursorColor = "#FFFFFF";
        cyan = "#3A96DD";
        foreground = "#CCCCCC";
        green = "#13A10E";
        purple = "#881798";
        red = "#C50F1F";
        selectionBackground = "#FFFFFF";
        white = "#CCCCCC";
        yellow = "#C19C00";
      };

      kittyDefault = {
        name = "Kitty Default";
        background = "#000000";
        black = "#000000";
        blue = "#0D73CC";
        brightBlack = "#767676";
        brightBlue = "#1A8FFF";
        brightCyan = "#14FFFF";
        brightGreen = "#23FD00";
        brightPurple = "#FD28FF";
        brightRed = "#F2201F";
        brightWhite = "#FFFFFF";
        brightYellow = "#FFFD00";
        cursorColor = "#CCCCCC";
        cyan = "#0DCDCD";
        foreground = "#DDDDDD";
        green = "#19CB00";
        purple = "#CB1ED1";
        red = "#CC0403";
        selectionBackground = "#FFFACD";
        white = "#DDDDDD";
        yellow = "#CECB00";
      };

      naysayer = {
        name = "Naysayer";
        background = "#062329";
        black = "#062329";
        blue = "#66D9EF";
        brightBlack = "#14676B";
        brightBlue = "#66D9EF";
        brightCyan = "#A1EFE4";
        brightGreen = "#A6E22E";
        brightPurple = "#AE81FF";
        brightRed = "#F92672";
        brightWhite = "#FFFFFF";
        brightYellow = "#E6DB74";
        cursorColor = "#FFFFFF";
        cyan = "#A1EFE4";
        foreground = "#D1B897";
        green = "#44B340";
        purple = "#FD5FF0";
        red = "#FF0000";
        selectionBackground = "#FFFFFF";
        white = "#D1B897";
        yellow = "#FFAA00";
      };
    };
  };
}
