let
  fonts = {
    sans = "Inter";
    mono = "JetBrainsMono Nerd Font";
  };

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

  stripHash = str:
    if builtins.substring 0 1 str == "#"
    then builtins.substring 1 (builtins.stringLength str - 1) str
    else str;
in {
  config.flake.lib = {
    inherit fonts theme;
    themeNoHash = builtins.mapAttrs (_: stripHash) theme;
  };
}
