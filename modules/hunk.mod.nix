_: {
  flake.nixosModules.hunk = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
    hasUserName = lib.hasAttrByPath ["userName"] options;
    hunk = pkgs.writeShellScriptBin "hunk" ''
      exec ${lib.getExe' pkgs.nodejs "npx"} --yes hunkdiff@beta "$@"
    '';
  in {
    config = lib.mkMerge [
      {
        environment.systemPackages = [hunk];
        programs.nix-ld.enable = true;
      }

      (lib.optionalAttrs (hasHjemUsers && hasUserName) {
        hjem.users.${config.userName}.xdg.config.files."hunk/config.toml".text = ''
          vcs = "jj"
        '';
      })
    ];
  };
}
