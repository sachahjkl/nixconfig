{inputs, ...}: {
  flake.nixosModules.shojiwm = {
    config,
    lib,
    ...
  }: {
    imports = [inputs.shojiwm.nixosModules.default];

    options.shojiwm.enable = lib.mkEnableOption "the ShojiWM Wayland compositor session";

    # The module adds a ShojiWM session to the display manager. The default
    # session stays the one set in display.defaultSession.
    config.programs.shojiwm = lib.mkIf config.shojiwm.enable {
      enable = true;
      initConfig = {
        enable = true;
        users = [config.userName];
      };
    };
  };
}
