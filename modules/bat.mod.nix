_: {
  flake.nixosModules.bat = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
    hasPersistDirs = lib.hasAttrByPath ["persist" "user" "directories"] options;
    hasUserName = lib.hasAttrByPath ["userName"] options;
    manPager = pkgs.writeShellScriptBin "man-pager" ''
      ${lib.getExe pkgs.unixtools.col} -bx | ${lib.getExe pkgs.bat} --language man --plain --color always | ${lib.getExe pkgs.less}
    '';
    normalUsers = lib.mapAttrsToList (name: _: name) (lib.filterAttrs (_: user: user.isNormalUser or false) config.users.users);
  in {
    config = lib.mkMerge [
      {
        programs.bat.enable = true;

        environment.sessionVariables = {
          LESS = "--quit-if-one-screen --quit-on-intr --ignore-case --incsearch --LONG-PROMPT --no-edit-warn --chop-long-lines --HILITE-UNREAD --tilde --RAW-CONTROL-CHARS";
          MANPAGER = lib.getExe manPager;
          MANROFFOPT = "-c";
          PAGER = lib.getExe pkgs.less;
        };

        system.activationScripts.batCache = lib.stringAfter ["users"] ''
          for user in ${lib.escapeShellArgs normalUsers}; do
            ${pkgs.util-linux}/bin/runuser --user "$user" -- ${lib.getExe pkgs.bat} cache --build
          done
        '';
      }

      (lib.optionalAttrs hasPersistDirs {
        persist.user.directories = [".cache/bat"];
      })

      (lib.optionalAttrs (hasHjemUsers && hasUserName) {
        hjem.users.${config.userName}.xdg.config.files."bat/config".text = ''
          --paging=never
        '';
      })
    ];
  };
}
