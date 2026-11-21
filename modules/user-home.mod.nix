{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.user-home = {
    config,
    lib,
    options,
    ...
  }: let
    user = config.userName;
    home = config.homeDirectory;
    faceIcon = lib.attrByPath ["assets" "faceIcon"] null config;
    hasHomeManager = lib.hasAttrByPath ["home-manager" "users"] options;
  in {
    config = lib.mkMerge [
      {
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
      }

      (lib.optionalAttrs hasHomeManager {
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
      })
    ];
  };
}
