_: {
  perSystem = {pkgs, ...}: {
    formatter = pkgs.writeShellApplication {
      name = "format-nix";
      runtimeInputs = [pkgs.alejandra];
      text = ''
        if (( $# == 0 )); then
          set -- .
        fi

        exec alejandra "$@"
      '';
    };
  };
}
