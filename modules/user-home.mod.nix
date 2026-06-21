{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.user-home = {
    config,
    lib,
    pkgs,
    ...
  }: let
    user = config.userName;
    home = config.homeDirectory;
    selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
    faceIcon = lib.attrByPath ["assets" "faceIcon"] null config;
    installTerminal = lib.attrByPath ["preferences" "userHome" "installTerminal"] true config;
    kittyUseThemeColors = lib.attrByPath ["preferences" "kitty" "useThemeColors"] false config;

    terminalPkg = self.lib.mkTerminal {
      inherit pkgs;
      fontFamily = config.preferences.theme.fonts.mono;
      shell = lib.getExe selfPkgs.userShell;
      useThemeColors = kittyUseThemeColors;
    };

    # xdg-terminal's generic fallback tries to execute $TERM as a command.
    # Inside kitty, $TERM is "xterm-kitty" (a terminfo name, not a binary).
    # Provide a compatibility wrapper so xdg-terminal works outside XFCE/GNOME/KDE.
    xtermKittyWrapper = pkgs.writeShellScriptBin "xterm-kitty" ''
      exec kitty "$@"
    '';
  in {
    options.preferences.userHome.installTerminal = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the wrapped Kitty terminal package and export TERMINAL=kitty.";
    };

    config = {
      hjem = {
        clobberByDefault = true;
        extraModules = [inputs.hjem-rum.hjemModules.default];
        users.${user} = {
          enable = true;
          inherit user;
          directory = home;

          environment.sessionVariables = {
            EDITOR = "nvim";
          };

          rum.environment.hideWarning = true;

          files = lib.mkMerge [
            (lib.optionalAttrs (faceIcon != null) {
              ".face.icon".source = faceIcon;
            })
          ];
        };
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {inherit inputs self;};
        sharedModules = [inputs.plasma-manager.homeModules.plasma-manager];
        users.${user} = {
          home = {
            username = user;
            homeDirectory = home;
            stateVersion = config.system.stateVersion;
          };

          programs.home-manager.enable = true;
        };
      };

      environment.systemPackages = lib.optionals installTerminal [
        terminalPkg
        xtermKittyWrapper
      ];
    };
  };
}
