_: {
  flake.nixosModules.kitty = {
    config,
    lib,
    pkgs,
    ...
  }: let
    terminalPreferences = lib.attrByPath ["terminal"] {} config;
    enabled = lib.attrByPath ["kitty" "enable"] false terminalPreferences || lib.attrByPath ["default"] null terminalPreferences == "kitty";
    terminalTheme = lib.attrByPath ["kitty" "theme"] config.theme.terminalPalette terminalPreferences;
    inherit (config) userName;
  in {
    config = lib.mkIf enabled {
      environment.systemPackages = [pkgs.kitty];

      hjem.users.${userName}.xdg.config.files."kitty/kitty.conf".text = ''
        enable_audio_bell no
        font_family ${config.theme.fonts.mono}
        font_size ${toString config.theme.fonts.size.normal}
        window_padding_width ${toString config.theme.padding}
        allow_remote_control yes
        shell_integration enabled
        background_opacity 0.85
        background_blur 5

        background ${terminalTheme.background}
        foreground ${terminalTheme.foreground}
        cursor ${terminalTheme.cursorColor}
        selection_background ${terminalTheme.selectionBackground}
        color0 ${terminalTheme.black}
        color1 ${terminalTheme.red}
        color2 ${terminalTheme.green}
        color3 ${terminalTheme.yellow}
        color4 ${terminalTheme.blue}
        color5 ${terminalTheme.purple}
        color6 ${terminalTheme.cyan}
        color7 ${terminalTheme.white}
        color8 ${terminalTheme.brightBlack}
        color9 ${terminalTheme.brightRed}
        color10 ${terminalTheme.brightGreen}
        color11 ${terminalTheme.brightYellow}
        color12 ${terminalTheme.brightBlue}
        color13 ${terminalTheme.brightPurple}
        color14 ${terminalTheme.brightCyan}
        color15 ${terminalTheme.brightWhite}
      '';
    };
  };
}
