{ self, ... }:

{
  flake.nixosModules.sacha-hjem = { config, lib, pkgs, ... }:
    let
      user = config.sacha.userName;
      home = config.sacha.homeDirectory;
      selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
      terminalPkg = self.lib.mkTerminal {
        inherit pkgs;
        shell = lib.getExe selfPkgs.environment;
        useThemeColors = config.sacha.kitty.useThemeColors;
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
              NH_FLAKE = "${config.sacha.nixConfigPath}";
            };

            files = {
              ".face.icon".source = config.sacha.assets.faceIcon;
            };
          };
        };

        environment.systemPackages = [
          terminalPkg
        ];
      };
    };
}
