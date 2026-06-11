_:

{
  flake.nixosModules.fonts = { config, pkgs, ... }: {
    fonts.fontconfig = {
      enable = true;
      antialias = true;
      defaultFonts = {
        sansSerif = [ config.preferences.theme.fonts.sans ];
        serif = [ "Inter" ];
        monospace = [ config.preferences.theme.fonts.mono ];
        emoji = [ "Noto Color Emoji" ];
      };
      hinting = {
        enable = true;
        style = "full";
      };
      subpixel.rgba = "rgb";
    };

    fonts.packages = with pkgs; [
      inter
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
    ];
  };
}
