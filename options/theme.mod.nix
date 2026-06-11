let
  theme = {
    # Campbell: the default Windows Terminal palette.
    base00 = "#0C0C0C";
    base01 = "#767676";
    base02 = "#767676";
    base03 = "#767676";
    base04 = "#CCCCCC";
    base05 = "#CCCCCC";
    base06 = "#F2F2F2";
    base07 = "#F2F2F2";
    base08 = "#C50F1F";
    base09 = "#C19C00";
    base0A = "#F9F1A5";
    base0B = "#13A10E";
    base0C = "#3A96DD";
    base0D = "#0037DA";
    base0E = "#881798";
    base0F = "#B4009E";
  };

  terminalTheme = {
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

  stripHash = str:
    if builtins.substring 0 1 str == "#"
    then builtins.substring 1 (builtins.stringLength str - 1) str
    else str;
in
{
  config.flake.lib = {
    inherit theme terminalTheme;
    themeNoHash = builtins.mapAttrs (_: stripHash) theme;
  };
}
