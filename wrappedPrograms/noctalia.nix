{ inputs, self, ... }:

{
  perSystem = { pkgs, ... }: {
    packages.noctalia-shell = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs;
      package = pkgs.noctalia-shell;
      env.NOCTALIA_CACHE_DIR = "/tmp/sacha-noctalia-cache";
      colors = {
        mError = self.lib.theme.base08;
        mHover = self.lib.theme.base0C;
        mOnError = self.lib.theme.base00;
        mOnHover = self.lib.theme.base00;
        mOnPrimary = self.lib.theme.base00;
        mOnSecondary = self.lib.theme.base00;
        mOnSurface = self.lib.theme.base07;
        mOnSurfaceVariant = self.lib.theme.base06;
        mOnTertiary = self.lib.theme.base00;
        mOutline = self.lib.theme.base03;
        mPrimary = self.lib.theme.base0B;
        mSecondary = self.lib.theme.base0A;
        mShadow = self.lib.theme.base00;
        mSurface = self.lib.theme.base00;
        mSurfaceVariant = self.lib.theme.base01;
        mTertiary = self.lib.theme.base0C;
      };
      settings = {
        appLauncher = {
          terminalCommand = "kitty -e";
          position = "center";
          viewMode = "list";
          iconMode = "tabler";
          showCategories = true;
          sortByMostUsed = true;
        };
        bar = {
          position = "left";
          density = "comfortable";
          exclusive = true;
          widgets = {
            center = [ ];
            left = [{ id = "ControlCenter"; } { id = "Workspace"; }];
            right = [{ id = "NotificationHistory"; } { id = "Volume"; } { id = "Battery"; } { id = "Clock"; } { id = "Tray"; }];
          };
        };
        general = {
          avatarImage = self + /nixos/features/face-icon/face.icon;
          animationSpeed = 1;
          dimmerOpacity = 0.15;
          language = "";
        };
        location = {
          name = "Paris";
          useFahrenheit = false;
        };
        screenRecorder = {
          frameRate = 60;
          videoCodec = "h264";
        };
      };
    };
  };
}
