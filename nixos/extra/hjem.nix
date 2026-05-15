{ self, ... }:

{
  flake.nixosModules.user-home = { config, lib, pkgs, ... }:
    let
      user = config.userName;
      home = config.homeDirectory;
      selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
      terminalPkg = self.lib.mkTerminal {
        inherit pkgs;
        shell = lib.getExe selfPkgs.userShell;
        useThemeColors = config.preferences.kitty.useThemeColors;
      };
    in
    {
      config = {
        hjem = {
          clobberByDefault = true;
          users.${user} = {
            enable = true;
            user = user;
            directory = home;

            environment.sessionVariables = {
              EDITOR = "nvim";
              TERMINAL = "kitty";
              NH_FLAKE = "${config.nixConfigPath}";
            };

            files = {
              ".face.icon".source = config.assets.faceIcon;
            };
          };
        };

        environment.systemPackages = [
          terminalPkg
        ];
      };
    };
}
