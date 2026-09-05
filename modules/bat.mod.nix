_: {
  flake.nixosModules.bat = {
    lib,
    pkgs,
    ...
  }: let
    manPager = pkgs.writeShellScriptBin "man-pager" ''
      set -o pipefail
      ${lib.getExe pkgs.unixtools.col} -bx | ${lib.getExe pkgs.bat} --paging=never --language man --plain --color always | ${lib.getExe pkgs.less}
    '';
  in {
    programs.bat = {
      enable = true;
      settings = {
        paging = "auto";
        pager = lib.getExe pkgs.less;
      };
    };

    programs.less.enable = true;

    # Keep aliases in interactive shells. Scripts still use coreutils cat.
    environment.shellAliases = {
      cat = lib.getExe pkgs.bat;
      page = "${lib.getExe pkgs.bat} --paging=always";
    };

    environment.sessionVariables = {
      LESS = "--quit-if-one-screen --quit-on-intr --ignore-case --incsearch --LONG-PROMPT --no-edit-warn --chop-long-lines --HILITE-UNREAD --tilde --RAW-CONTROL-CHARS";
      MANPAGER = lib.getExe manPager;
      MANROFFOPT = "-c";
      PAGER = lib.getExe pkgs.less;
      JJ_PAGER = lib.getExe pkgs.less;
    };
  };
}
