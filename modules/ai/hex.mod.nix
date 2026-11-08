{inputs, ...}: {
  flake.nixosModules.hex = {
    config,
    lib,
    ...
  }: let
    cfg = config.ai.hex;
  in {
    options.ai.hex.enable = lib.mkEnableOption "Hex local voice dictation";

    config = lib.mkIf cfg.enable {
      home-manager.users.${config.userName} = {
        imports = [inputs.hex.homeManagerModules.hex];
        programs.hex = {
          enable = true;
          autostart = true;
          installModel = true;
        };
      };

      persist.user.directories = [
        ".local/share/hex"
      ];
    };
  };
}
