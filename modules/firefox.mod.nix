_: {
  flake.nixosModules.firefox = {
    config,
    lib,
    ...
  }: {
    options.apps.firefox.enable = lib.mkEnableOption "Firefox browser";

    config = lib.mkIf config.apps.firefox.enable {
      programs.firefox.enable = true;
      persist.user.directories = [".mozilla"];
    };
  };
}
