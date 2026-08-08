{self, ...}: {
  flake.nixosModules.kidsAccounts = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.kidsDesktop.accounts;
    accountType = lib.types.submodule {
      options = {
        fullName = lib.mkOption {
          type = lib.types.str;
          description = "Name shown by the display manager.";
        };

        passwordHash = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Declarative account password hash. A null value keeps the account locked.";
        };
      };
    };
    childAccount = _: account:
      {
        isNormalUser = true;
        description = account.fullName;
        extraGroups = [
          "audio"
          "input"
          "networkmanager"
          "video"
        ];
        shell = pkgs.bashInteractive;
      }
      // lib.optionalAttrs (account.passwordHash != null) {
        hashedPassword = account.passwordHash;
      };
  in {
    options.kidsDesktop.accounts = {
      administrator = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "parent";
          description = "Local administrator account name.";
        };

        fullName = lib.mkOption {
          type = lib.types.str;
          default = "Parent";
          description = "Local administrator display name.";
        };

        passwordHashFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "File containing the administrator password hash. A null value keeps password login locked.";
        };
      };

      children = lib.mkOption {
        type = lib.types.attrsOf accountType;
        default = {};
        description = "Local child accounts without administrator privileges.";
      };
    };

    config = {
      assertions = [
        {
          assertion = !(builtins.hasAttr cfg.administrator.name cfg.children);
          message = "The kids-desktop administrator and child account names must differ.";
        }
      ];

      users = {
        mutableUsers = false;
        users =
          lib.mapAttrs childAccount cfg.children
          // {
            ${cfg.administrator.name} =
              {
                isNormalUser = true;
                description = cfg.administrator.fullName;
                extraGroups = [
                  "networkmanager"
                  "wheel"
                ];
                shell = pkgs.bashInteractive;
                openssh.authorizedKeys.keys = self.keys-admin;
              }
              // lib.optionalAttrs (cfg.administrator.passwordHashFile != null) {
                hashedPasswordFile = toString cfg.administrator.passwordHashFile;
              };
          };
      };

      security.sudo.wheelNeedsPassword = true;
    };
  };
}
