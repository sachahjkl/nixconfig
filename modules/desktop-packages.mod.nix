_: {
  flake.nixosModules.desktop-packages = {
    config,
    pkgs,
    ...
  }: let
    desktopEssentials = with pkgs; [
      baobab
      file-roller
      gthumb
      hunspell
      hunspellDicts.en-us
      hunspellDicts.fr-any
      keepassxc
      libreoffice-qt
      losslesscut-bin
      p7zip
      qalculate-gtk
    ];
  in {
    environment.systemPackages =
      desktopEssentials
      ++ (with pkgs; [
        alsa-utils
        audacity
        equibop
        efibootmgr
        file-roller
        fff
        ffmpeg-full
        gparted
        imagemagick
        mediainfo
        mpv
        pwvucontrol
        qemu
        sbctl
        seahorse
        spice
        spice-gtk
        telegram-desktop
        virt-viewer
        vlc
        xdg-utils
        zed-editor
        neovide
      ]);

    persist.user = {
      directories = [
        ".audacity-data"
        ".cache/zed"
        ".config/equibop"
        ".config/vlc"
        ".config/zed"
        ".local/share/TelegramDesktop"
        ".local/share/zed"
      ];

      files = [
        ".config/equibop-flags.conf"
      ];
    };

    hjem.users.${config.userName}.rum.programs = {
      # Disabled on purpose so Zed keeps a writable user-managed config.
      # zed = {
      #   enable = true;
      #   settings = {
      #     load_direnv = "shell_hook";
      #     vim_mode = false;
      #     ui_font_family = config.theme.fonts.sans;
      #     buffer_font_family = config.theme.fonts.mono;
      #     buffer_font_size = 14;
      #     theme = {
      #       mode = "system";
      #       light = "One Light";
      #       dark = "One Dark";
      #     };
      #   };
      # };

      neovide = {
        enable = true;
        package = null;
        settings = {
          theme = "auto";
          vsync = true;
          maximized = false;
          font = {
            normal = [config.theme.fonts.mono];
            size = 14.0;
          };
        };
      };
    };
  };
}
