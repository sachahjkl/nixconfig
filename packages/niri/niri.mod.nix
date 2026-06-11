{ inputs, lib, self, ... }:

{
  flake.wrappersModules.niri = { config, lib, pkgs, ... }: {
    options.terminal = lib.mkOption {
      type = lib.types.str;
      default = "kitty";
    };

    config.settings =
      let
        noctaliaExe = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia-shell;
        mkWhichKeyExe = menu:
          let
            yaml = (pkgs.formats.yaml { }).generate "wlr-which-key.yaml" {
              inherit menu;
              font = "JetBrainsMono Nerd Font 12";
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
          in
          lib.getExe (inputs.wrappers.lib.wrapPackage {
            inherit pkgs;
            package = pkgs.wlr-which-key;
            args = [ (toString yaml) ];
          });
      in
      {
        prefer-no-csd = _: { };
        input = {
          focus-follows-mouse = _: { };
          keyboard = {
            xkb = {
              layout = "fr,us";
              options = "grp:alt_shift_toggle,caps:escape";
            };
            repeat-rate = 40;
            repeat-delay = 250;
          };
          touchpad = {
            natural-scroll = _: { };
            tap = _: { };
          };
          mouse.accel-profile = "flat";
        };
        binds = {
          "Mod+Return".spawn = config.terminal;
          "Mod+Q".close-window = _: { };
          "Mod+F".maximize-column = _: { };
          "Mod+G".fullscreen-window = _: { };
          "Mod+Shift+F".toggle-window-floating = _: { };
          "Mod+D".spawn-sh = mkWhichKeyExe [
            {
              key = "b";
              desc = "Bluetooth";
              cmd = "${noctaliaExe} ipc call bluetooth togglePanel";
            }
            {
              key = "w";
              desc = "WiFi";
              cmd = "${noctaliaExe} ipc call wifi togglePanel";
            }
            {
              key = "t";
              desc = "Terminal";
              cmd = config.terminal;
            }
            {
              key = "f";
              desc = "Firefox";
              cmd = "firefox";
            }
            {
              key = "e";
              desc = "Equibop";
              cmd = "equibop";
            }
            {
              key = "p";
              desc = "Audio";
              cmd = "${lib.getExe pkgs.pwvucontrol}";
            }
          ];
          "Mod+H".focus-column-left = _: { };
          "Mod+L".focus-column-right = _: { };
          "Mod+K".focus-window-up = _: { };
          "Mod+J".focus-window-down = _: { };
          "Mod+Shift+H".move-column-left = _: { };
          "Mod+Shift+L".move-column-right = _: { };
          "Mod+Shift+K".move-window-up = _: { };
          "Mod+Shift+J".move-window-down = _: { };
          "Mod+S".spawn-sh = "${noctaliaExe} ipc call launcher toggle";
          "Mod+V".spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          "XF86AudioRaiseVolume".spawn-sh = "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+";
          "XF86AudioLowerVolume".spawn-sh = "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-";
          "XF86AudioMute".spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "Mod+Shift+S".spawn-sh = ''${lib.getExe pkgs.grim} -g "$(${lib.getExe pkgs.slurp} -w 0)" - | ${pkgs.wl-clipboard}/bin/wl-copy'';
        };
        layout = {
          gaps = 5;
          focus-ring = {
            width = 2;
            active-color = self.lib.theme.base09;
          };
        };
        workspaces = builtins.listToAttrs (map
          (i: {
            name = "w${toString i}";
            value.layout.gaps = 5;
          }) [ 0 1 2 3 4 5 6 7 8 9 ]);
        xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;
        spawn-at-startup = [
          noctaliaExe
          (lib.getExe (pkgs.writeShellScriptBin "wallpaper" "${lib.getExe pkgs.swaybg} -i ${self + /nixos/features/wallpaper/wallpaper.jpg} -m fill"))
        ];
      };
  };

  perSystem = { pkgs, self', ... }: {
    packages.niri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;
      imports = [ self.wrappersModules.niri ];
      terminal = lib.getExe self'.packages.terminal;
    };
  };
}
