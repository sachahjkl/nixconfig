{self, ...}: {
  flake.nixosModules.baseUser = {
    config,
    pkgs,
    lib,
    ...
  }: let
    selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
  in {
    imports = [self.nixosModules.secrets];

    options = {
      passwordHashFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to a local password-hash file for the primary user.";
      };

      localPasswordHash = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Fallback declarative password hash when not using agenix secrets.";
      };

      nixConfigPath = lib.mkOption {
        type = lib.types.str;
        default = self.outPath;
        description = "Local path to this Nix flake checkout.";
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

      extraUserGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional groups for the primary local user.";
      };
    };

    config = {
      users = {
        mutableUsers = lib.mkDefault false;

        users.${config.userName} =
          {
            isNormalUser = true;
            description = config.fullName;
            extraGroups = ["wheel"] ++ config.extraUserGroups;
            shell = selfPkgs.userShell;
          }
          // lib.optionalAttrs (config.passwordHashFile != null) {
            hashedPasswordFile = toString config.passwordHashFile;
          }
          // lib.optionalAttrs (config.passwordHashFile == null && config.localPasswordHash != null) {
            hashedPassword = config.localPasswordHash;
          };
      };

      system.activationScripts.accountsServiceUserIcon = let
        faceIcon = lib.attrByPath ["assets" "faceIcon"] null config;
      in
        lib.mkIf (faceIcon != null) (lib.stringAfter ["users"] ''
          mkdir -p /var/lib/AccountsService/icons /var/lib/AccountsService/users
          ln -sfn ${faceIcon} /var/lib/AccountsService/icons/${config.userName}
          cat > /var/lib/AccountsService/users/${config.userName} <<'EOF'
          [User]
          Icon=/var/lib/AccountsService/icons/${config.userName}
          SystemAccount=false
          EOF
        '');
    };
  };
}
