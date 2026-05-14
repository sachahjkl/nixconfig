{ ... }:

{
  flake.nixosModules.sacha-user = { config, pkgs, lib, ... }: {
    users.users.${config.sacha.userName} = {
      isNormalUser = true;
      description = config.sacha.fullName;
      extraGroups = [ "networkmanager" "wheel" "audio" "video" "podman" "libvirtd" "kvm" ];
      shell = pkgs.fish;
    };

    system.activationScripts.accountsServiceSachaIcon = lib.stringAfter [ "users" ] ''
      mkdir -p /var/lib/AccountsService/icons /var/lib/AccountsService/users
      ln -sfn ${config.sacha.assets.faceIcon} /var/lib/AccountsService/icons/${config.sacha.userName}
      cat > /var/lib/AccountsService/users/${config.sacha.userName} <<'EOF'
      [User]
      Icon=/var/lib/AccountsService/icons/${config.sacha.userName}
      SystemAccount=false
      EOF
    '';
  };
}
