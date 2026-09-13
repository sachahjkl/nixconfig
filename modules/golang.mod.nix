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

      (lib.optionalAttrs hasHomeDirectory {
        environment = {
          extraInit = ''
            export PATH="${config.homeDirectory}/.local/share/go/bin:$PATH"
          '';
          sessionVariables.GOPATH = "${config.homeDirectory}/.local/share/go";
        };
      })

      (lib.optionalAttrs (hasHjemUsers && hasUserName) {
        hjem.users.${config.userName}.xdg.data.files."go".type = "directory";
      })

      (lib.optionalAttrs hasPersistDirectories {
        persist.user.directories = [".local/share/go"];
      })
    ];
  };
}
