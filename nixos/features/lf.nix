{ lib, ... }:

{
  flake.nixosModules.lf = { config, pkgs, ... }:
    let
      home = config.sacha.homeDirectory;
    in
    {
      hjem.users.${config.sacha.userName}.xdg.config.files."lf/lfrc".text = ''
        set reverse true
        set preview true
        set hidden true
        set drawbox true
        set icons true
        set ignorecase true

        cmd stripspace %stripspace "$f"

        map "\""
        map o
        map d
        map e
        map f
        map . set hidden!
        map D delete
        map p paste
        map dd cut
        map y copy
        map ` mark-load
        map \' mark-load
        map <enter> open
        map a rename
        map r reload
        map C clear
        map U unselect

        map do $ ${lib.getExe pkgs.ripdrag} -a -x "$fx"

        map g~ cd
        map gh cd
        map g/ /
        map gd cd ${home}/Downloads
        map gt cd /tmp
        map gv cd ${home}/Videos
        map go cd ${home}/Documents
        map gc cd ${home}/.config
        map gn cd ${config.sacha.nixConfigPath}
        map gp cd ${home}/Projects
        map gs cd ${home}/.local/share
        map gm cd /run/media

        map eE $ $EDITOR "$f"
        map ee $ ${lib.getExe pkgs.direnv} exec . $EDITOR "$f"
        map e. $ ${lib.getExe pkgs.direnv} exec . $EDITOR .
        map V $ ${lib.getExe pkgs.bat} --paging=always "$f"

        map <C-d> 5j
        map <C-u> 5k

        setlocal ${home}/Projects sortby time
        setlocal ${home}/Projects/* sortby time
        setlocal ${home}/Downloads/ sortby time
      '';

      sacha.preservation.user.directories = [ ".local/share/lf" ];
    };
}
