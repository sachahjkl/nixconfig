_: {
  perSystem = {pkgs, ...}: let
    update = pkgs.writeShellApplication {
      name = "update";
      runtimeInputs = with pkgs; [
        curl
        git
        gnused
        gnutar
        jq
        nix
        nodejs_22
        prefetch-npm-deps
      ];
      text = builtins.readFile ./update.sh;
    };
  in {
    apps.update = {
      type = "app";
      program = "${update}/bin/update";
      meta.description = "Update flake inputs and hand-pinned package versions";
    };
  };
}
