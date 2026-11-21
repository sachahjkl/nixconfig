let
  fonts = {
    sans = "Inter";
    mono = "JetBrainsMono Nerd Font";
  };

  terminalThemes.kittyDefault = {
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
in {
  config.flake.lib = {
    inherit fonts terminalThemes;
  };
}
