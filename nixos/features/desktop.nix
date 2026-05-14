{ ... }:

{
  flake.nixosModules.desktop = { config, lib, pkgs, ... }:
    let
      isHyprland = lib.elem config.desktop.environment [ "hyprland" "both" "all" ];
      isNiri = lib.elem config.desktop.environment [ "niri" "both" "all" ];
    in
    {
      options.desktop.environment = lib.mkOption {
        type = lib.types.enum [ "hyprland" "niri" "both" "all" ];
        default = "niri";
        description = "Desktop environment to enable";
      };

      config = lib.mkMerge [
        {
          services.displayManager.ly.enable = true;
          services.accounts-daemon.enable = true;

          services.xserver.enable = false;
          services.xserver.xkb = {
            layout = "fr";
            variant = "";
          };

          programs.firefox.enable = true;
          security.polkit.enable = true;
          security.polkit.extraConfig = ''
            polkit.addRule(function(action, subject) {
              if (subject.isInGroup("wheel"))
                return polkit.Result.YES;
            });
          '';
          environment.systemPackages = with pkgs; [ gparted ];

          qt.enable = true;

          programs.xfconf.enable = true;
          programs.thunar = {
            enable = true;
            plugins = with pkgs; [
              thunar-archive-plugin
              thunar-media-tags-plugin
              thunar-volman
            ];
          };

          xdg.portal.enable = true;

          services.printing.enable = true;
          services.printing.listenAddresses = [ "localhost:631" ];
          services.printing.defaultShared = false;
          services.gvfs.enable = true;
          services.tumbler.enable = true;
          services.udisks2.enable = true;

          services.avahi = {
            enable = true;
            nssmdns4 = true;
            openFirewall = true;
          };

          services.pulseaudio.enable = false;
          security.rtkit.enable = true;
          services.pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
          };
        }

        (lib.mkIf (isHyprland || isNiri) {
          qt.platformTheme = "qt5ct";
          xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
          xdg.portal.config.common = {
            default = [ "gtk" ];
            "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          };
        })
      ];
    };
}
