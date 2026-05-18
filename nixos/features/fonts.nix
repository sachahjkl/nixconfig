{ ... }:

{
  flake.nixosModules.fonts = { config, pkgs, ... }: {
    fonts.fontconfig = {
      enable = true;
      antialias = true;
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

    hjem.users.${config.userName}.xdg.config.files."fontconfig/fonts.conf".text = ''
      <?xml version='1.0'?>
      <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
      <fontconfig>
        <alias><family>sans-serif</family><prefer><family>${config.preferences.theme.fonts.sans}</family></prefer></alias>
        <alias><family>serif</family><prefer><family>Noto Serif</family></prefer></alias>
        <alias><family>monospace</family><prefer><family>${config.preferences.theme.fonts.mono}</family></prefer></alias>
        <match target="font">
          <edit name="antialias" mode="assign"><bool>true</bool></edit>
          <edit name="hinting" mode="assign"><bool>true</bool></edit>
          <edit name="hintstyle" mode="assign"><const>hintfull</const></edit>
          <edit name="rgba" mode="assign"><const>rgb</const></edit>
        </match>
      </fontconfig>
    '';
  };
}
