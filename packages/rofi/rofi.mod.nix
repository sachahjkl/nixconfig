{inputs, ...}: {
  flake.lib.mkRofi = {
    pkgs,
    theme,
  }:
    inputs.wrapper-modules.wrappers.rofi.wrap {
      inherit pkgs theme;
      settings = {
        modi = ["drun" "run" "window"];
        show-icons = true;
      };
    };
}
