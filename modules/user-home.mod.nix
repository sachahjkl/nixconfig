{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.user-home = {
    config,
    lib,
    ...
  }: let
    user = config.userName;
    home = config.homeDirectory;
    faceIcon = lib.attrByPath ["assets" "faceIcon"] null config;
  in {
    config = {
      hjem = {
        clobberByDefault = true;
        extraModules = [inputs.hjem-rum.hjemModules.default];
        users.${user} = {
          enable = true;
          inherit user;
          directory = home;

          environment.sessionVariables = {
            EDITOR = config.editor.command;
            VISUAL = config.editor.command;
            GIT_EDITOR = config.editor.watchCommand;
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
        users.${user} = {
          home = {
            username = user;
            homeDirectory = home;
            stateVersion = config.system.stateVersion;
          };

          manual.manpages.enable = false;
          programs.home-manager.enable = true;
        };
      };
    };
  };
}
