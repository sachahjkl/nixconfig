_: {
  flake.nixosModules.fonts = {
    config,
    pkgs,
    ...
  }: {
    fonts = {
      fontconfig = {
        enable = true;
        antialias = true;
        defaultFonts = {
          sansSerif = [config.preferences.theme.fonts.sans];
          serif = [config.preferences.theme.fonts.sans];
          monospace = [config.preferences.theme.fonts.mono];
          emoji = ["Noto Color Emoji"];
        };
        hinting = {
          enable = true;
          style = "full";
        };
        subpixel.rgba = "rgb";
      };

      packages = with pkgs; [
        inter
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-color-emoji
      ];
    };
  };
}
