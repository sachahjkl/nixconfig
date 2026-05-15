{ inputs
, lib
, ...
}:

{
  perSystem =
    { pkgs
    , self'
    , ...
    }:
    let
      fishConf = pkgs.writeText "fish-config" ''
        function fish_prompt
            string join "" -- (set_color red) "[" (set_color yellow) $USER (set_color green) "@" (set_color blue) $hostname (set_color magenta) " " (prompt_pwd) (set_color red) "]" (set_color normal) "\$ "
        end

        set fish_greeting
        fish_vi_key_bindings

        ${lib.getExe pkgs.zoxide} init fish | source

        function lf --wraps="lf" --description="lf - Terminal file manager (changing directory on exit)"
            cd "$(command lf -print-last-dir $argv)"
        end

        if type -q direnv
            direnv hook fish | source
        end
      '';
    in
    {
      packages.fish = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.fish;
        runtimeInputs = [ pkgs.carapace pkgs.direnv pkgs.starship pkgs.zoxide ];
        flags."-C" = "source ${fishConf}";
      };
    };
}
