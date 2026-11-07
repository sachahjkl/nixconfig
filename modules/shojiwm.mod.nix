{inputs, ...}: {
  flake.nixosModules.shojiwm = {
    config,
    lib,
    pkgs,
    ...
  }: let
    win7 = inputs.shojiwm-win7.packages.${pkgs.stdenv.hostPlatform.system}.default;
    configHome = "${config.homeDirectory}/.config/shojiwm";
  in {
    imports = [inputs.shojiwm.nixosModules.default];

    options.shojiwm.enable = lib.mkEnableOption "the ShojiWM Wayland compositor session with the Windows 7 configuration";

    # The module adds a ShojiWM session to the display manager. The default
    # session stays the one set in display.defaultSession.
    config = lib.mkIf config.shojiwm.enable {
      programs.shojiwm = {
        enable = true;
        # Creates package.json and the shoji_wm link in ~/.config/shojiwm.
        initConfig = {
          enable = true;
          users = [config.userName];
        };
      };

      # The Control Panel's light or dark choice is the dconf colour scheme,
      # which the settings portal (xdg-desktop-portal-gtk, from the ShojiWM
      # module) hands to every program. Set here too, so the session has it
      # whatever else the host imports.
      programs.dconf.enable = true;

      # The Windows 7 configuration needs these at run time.
      environment.systemPackages = with pkgs; [
        inter
        kitty
        quickshell
      ];

      systemd.user.tmpfiles.users.${config.userName}.rules = map (name: "L+ ${configHome}/${name} - - - - ${win7}/${name}") [
        "src"
        "assets"
        "shell"
      ];
    };
  };
}
