{
  inputs,
  self,
  lib,
  ...
}: let
  mkWhichKey = pkgs: {
    menu,
    font ? "${self.lib.fonts.mono} 12",
  }:
    (self.wrappersModules.which-key.apply {
      inherit pkgs;
      settings = {
        inherit font menu;

        background = self.lib.theme.base00;
        color = self.lib.theme.base06;
        border = self.lib.theme.base0F;
        separator = " -> ";
        border_width = 2;
        corner_r = 15;
        padding = 15;
        rows_per_column = 5;
        column_padding = 25;

        anchor = "bottom-right";
        margin_right = 0;
        margin_bottom = 5;
        margin_left = 5;
        margin_top = 0;
      };
    }).wrapper;
in {
  flake = {
    mkWhichKeyExe = pkgs: menu: lib.getExe (mkWhichKey pkgs {inherit menu;});
    mkWhichKeyExeWith = pkgs: args: lib.getExe (mkWhichKey pkgs args);

    wrappersModules.which-key = inputs.wrappers.lib.wrapModule (
      {
        config,
        lib,
        ...
      }: let
        yamlFormat = config.pkgs.formats.yaml {};
      in {
        options.settings = lib.mkOption {
          inherit (yamlFormat) type;
        };

        config = {
          package = config.pkgs.wlr-which-key;
          args = [(toString (yamlFormat.generate "config.yaml" config.settings))];
        };
      }
    );
  };
}
