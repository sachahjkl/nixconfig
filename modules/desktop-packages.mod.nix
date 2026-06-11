{ ... }:

{
  flake.nixosModules.desktop-packages = { config, pkgs, ... }: {
    preferences.preservation.user.directories = [
      ".audacity-data"
      ".config/equibop"
      ".config/vlc"
      ".config/zed"
      ".local/share/TelegramDesktop"
      ".local/share/zed"
    ];

    preferences.preservation.user.files = [
      ".config/equibop-flags.conf"
    ];

    hjem.users.${config.userName}.rum.programs = {
      zed = {
        enable = true;
        settings = {
          load_direnv = "shell_hook";
          vim_mode = false;
          ui_font_family = config.preferences.theme.fonts.sans;
          buffer_font_family = config.preferences.theme.fonts.mono;
          buffer_font_size = 14;
          theme = {
            mode = "system";
            light = "One Light";
            dark = "One Dark";
          };
        };
      };

      neovide = {
        enable = true;
        package = null;
        settings = {
          theme = "auto";
          vsync = true;
          maximized = false;
          font = {
            normal = [ config.preferences.theme.fonts.mono ];
            size = 14.0;
          };
        };
      };
    };

    environment.systemPackages = with pkgs; [
      alsa-utils
      audacity
      bcompare
      equibop
      efibootmgr
      fff
      ffmpeg-full
      imagemagick
      mediainfo
      mpv
      pwvucontrol
      qemu
      sbctl
      spice
      spice-gtk
      telegram-desktop
      virt-viewer
      vlc
      zed-editor
      neovide
    ];
  };
}
