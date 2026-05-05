{ lib, inputs, ... }:

{
  options.sacha.dotfilesPath = lib.mkOption {
    type = lib.types.str;
    default = "/home/sacha/Devel/dotfiles";
    description = "Local path to this dotfiles flake checkout.";
  };

  options.sacha.userName = lib.mkOption {
    type = lib.types.str;
    default = "sacha";
    description = "Primary local username.";
  };

  options.sacha.fullName = lib.mkOption {
    type = lib.types.str;
    default = "Sacha";
    description = "Primary local full name.";
  };

  options.sacha.homeDirectory = lib.mkOption {
    type = lib.types.str;
    default = "/home/sacha";
    description = "Primary local home directory.";
  };

  options.sacha.assets = {
    wallpaper = lib.mkOption {
      type = lib.types.path;
      default = ./assets/wallpaper.jpg;
      description = "Shared wallpaper asset path.";
    };

    faceIcon = lib.mkOption {
      type = lib.types.path;
      default = ./assets/face.icon;
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

  imports = [
    inputs.helium.nixosModules.helium
    ./modules/base.nix
    ./modules/desktop.nix
    ./modules/hyprland
    ./modules/packages.nix
    ./modules/shell.nix
    ./users/sacha/nixos.nix
  ];
}
