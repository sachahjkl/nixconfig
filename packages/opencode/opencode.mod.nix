{ inputs, lib, self, ... }:

{
  flake.lib.defaultOpenCodeSettings = pkgs: {
    autoupdate = false;
    share = "disabled";
    permission = {
      external_directory = {
        "/home/sacha/Projects/**" = "allow";
      };
      lsp = "allow";
      webfetch = "allow";
      websearch = "allow";
    };
    watcher.ignore = [
      ".direnv/**"
      ".git/**"
      "dist/**"
      "node_modules/**"
      "result/**"
    ];
    lsp.nix = {
      command = [ (lib.getExe pkgs.nixd) ];
      extensions = [ ".nix" ];
    };
  };

  flake.lib.mkOpenCodeConfig =
    { pkgs
    , settings ? { }
    }:
    pkgs.writeText "opencode.json" (
      builtins.toJSON ({
        "$schema" = "https://opencode.ai/config.json";
      } // self.lib.defaultOpenCodeSettings pkgs // settings)
    );

  flake.wrappersModules.opencode = inputs.wrappers.lib.wrapModule (
    { config, lib, ... }:
    let
      configFile = config.pkgs.writeText "opencode.json" (
        builtins.toJSON ({
          "$schema" = "https://opencode.ai/config.json";
        } // self.lib.defaultOpenCodeSettings config.pkgs // config.settings)
      );
    in
    {
      options.settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
      };

      config = {
        package = lib.mkDefault config.pkgs.opencode;
        env.OPENCODE_CONFIG = toString configFile;
        # https://opencode.ai/docs/tools/#websearch
        env.OPENCODE_ENABLE_EXA = "1";
      };
    }
  );

  flake.nixosModules.opencode = { pkgs, ... }:
    let
      selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      preferences.preservation.user.directories = [
        ".config/opencode"
        ".local/share/opencode"
      ];

      environment.systemPackages = [ selfPkgs.opencode ];
    };

  perSystem = { pkgs, ... }: {
    packages.opencode-unwrapped =
      let
        packageJson = builtins.fromJSON (builtins.readFile (inputs.opencode-src + /packages/opencode/package.json));
      in
      pkgs.opencode.overrideAttrs (finalAttrs: previousAttrs: {
        version = packageJson.version;
        src = inputs.opencode-src;
        node_modules = previousAttrs.node_modules.overrideAttrs {
          version = packageJson.version;
          src = inputs.opencode-src;
          outputHash = "sha256-m0uTWu/JrzeUJXkaIlYf8TgrwMmMKwRsELHe5NAKPDY=";
        };
      });

    packages.opencode = (self.wrappersModules.opencode.apply {
      inherit pkgs;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.opencode-unwrapped;
      settings = {
      };
    }).wrapper;
  };
}
