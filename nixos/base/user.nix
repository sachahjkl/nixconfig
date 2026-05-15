{ self, ... }:

{
  flake.nixosModules.base = { config, pkgs, lib, ... }:
    let
      selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      options = {
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
      };

      config = {
        users.users.${config.userName} = {
          isNormalUser = true;
          description = config.fullName;
          extraGroups = [ "networkmanager" "wheel" "audio" "video" "podman" "libvirtd" "kvm" ];
          shell = selfPkgs.userShell;
        };

        system.activationScripts.accountsServiceUserIcon = lib.stringAfter [ "users" ] ''
          mkdir -p /var/lib/AccountsService/icons /var/lib/AccountsService/users
          ln -sfn ${config.assets.faceIcon} /var/lib/AccountsService/icons/${config.userName}
          cat > /var/lib/AccountsService/users/${config.userName} <<'EOF'
          [User]
          Icon=/var/lib/AccountsService/icons/${config.userName}
          SystemAccount=false
          EOF
        '';
      };
  };
}
