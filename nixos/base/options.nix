{ config, lib, ... }:

{
  options.sacha = {
    dotfilesPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/sacha/Projects/dotfiles";
      description = "Local path to this dotfiles flake checkout.";
    };

    userName = lib.mkOption {
      type = lib.types.str;
      default = "sacha";
      description = "Primary local username.";
    };

    fullName = lib.mkOption {
      type = lib.types.str;
      default = "Sacha";
      description = "Primary local full name.";
    };

    homeDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/home/sacha";
      description = "Primary local home directory.";
    };

    git = {
      authorName = lib.mkOption {
        type = lib.types.str;
        default = "sachahjkl";
        description = "Default Git author name for wrapped Git.";
      };

      authorEmail = lib.mkOption {
        type = lib.types.str;
        default = "sacha@sacha.house";
        description = "Default Git author email for wrapped Git.";
      };
    };

    kitty = {
      useThemeColors = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether Kitty should use the shared terminal color palette on this host.";
      };
    };
  };

  config.flake.nixosModules.common = { lib, ... }: {
    options.sacha.dotfilesPath = lib.mkOption {
      type = lib.types.str;
      default = config.sacha.dotfilesPath;
      description = "Local path to this dotfiles flake checkout.";
    };

    options.sacha.userName = lib.mkOption {
      type = lib.types.str;
      default = config.sacha.userName;
      description = "Primary local username.";
    };

    options.sacha.fullName = lib.mkOption {
      type = lib.types.str;
      default = config.sacha.fullName;
      description = "Primary local full name.";
    };

    options.sacha.homeDirectory = lib.mkOption {
      type = lib.types.str;
      default = config.sacha.homeDirectory;
      description = "Primary local home directory.";
    };

    options.sacha.kitty.useThemeColors = lib.mkOption {
      type = lib.types.bool;
      default = config.sacha.kitty.useThemeColors;
      description = "Whether Kitty should use the shared terminal color palette on this host.";
    };

    options.sacha.assets = {
      wallpaper = lib.mkOption {
        type = lib.types.path;
        description = "Shared wallpaper asset path.";
      };

      faceIcon = lib.mkOption {
        type = lib.types.path;
        description = "Shared face icon asset path.";
      };
    };

    options.sacha.theme = {
      cursor = lib.mkOption {
        type = lib.types.str;
        default = "Posy_Cursor_Black_125_175";
        description = "Shared cursor theme name.";
      };

      cursorSize = lib.mkOption {
        type = lib.types.int;
        default = 48;
        description = "Shared cursor size.";
      };

      gtkTheme = lib.mkOption {
        type = lib.types.str;
        default = "Arc-Dark";
        description = "Shared GTK theme name.";
      };

      iconTheme = lib.mkOption {
        type = lib.types.str;
        default = "Papirus-Dark";
        description = "Shared icon theme name.";
      };

      rofiTheme = lib.mkOption {
        type = lib.types.str;
        default = "Arc-Dark";
        description = "Shared Rofi theme name.";
      };

      kvantumTheme = lib.mkOption {
        type = lib.types.str;
        default = "KvArcDark";
        description = "Shared Kvantum theme name.";
      };

      fonts = {
        sans = lib.mkOption {
          type = lib.types.str;
          default = "Inter";
          description = "Shared sans-serif UI font name.";
        };

        mono = lib.mkOption {
          type = lib.types.str;
          default = "JetBrainsMono Nerd Font";
          description = "Shared monospace UI font name.";
        };
      };
    };
  };
}
