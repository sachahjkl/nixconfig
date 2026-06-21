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
          sansSerif = [config.theme.fonts.sans];
          serif = [config.theme.fonts.sans];
          monospace = [config.theme.fonts.mono];
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
