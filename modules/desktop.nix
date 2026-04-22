{ pkgs, ... }:

{
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  programs.firefox.enable = true;
  programs.partition-manager.enable = true;

  qt = {
    enable = true;
    platformTheme = "kde";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  };

  services.printing.enable = true;
  services.printing.listenAddresses = [ "localhost:631" ];
  services.printing.defaultShared = false;

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
