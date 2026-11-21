_: {
  flake.nixosModules.golang = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
    hasHomeDirectory = lib.hasAttrByPath ["homeDirectory"] options;
    hasPersistDirectories = lib.hasAttrByPath ["persist" "user" "directories"] options;
    hasUserName = lib.hasAttrByPath ["userName"] options;
  in {
    config = lib.mkMerge [
      {
        environment.systemPackages = [
          pkgs.go
          pkgs.gopls
        ];
      }

      (lib.optionalAttrs (hasHjemUsers && hasHomeDirectory && hasUserName) {
        hjem.users.${config.userName} = {
          environment.sessionVariables.GOPATH = "${config.homeDirectory}/.local/share/go";
          xdg.data.files."go".type = "directory";
          files.".config/fish/conf.d/golang.fish".text = ''
            fish_add_path --global --move ${config.homeDirectory}/.local/share/go/bin
          '';
        };
      })

      (lib.optionalAttrs hasPersistDirectories {
        persist.user.directories = [".local/share/go"];
      })
    ];
  };
}
