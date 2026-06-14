{
  inputs,
  self,
  ...
}: {
  flake = {
    nixosModules.deployUser = {
      users.users.deploy = {
        isNormalUser = true;
        description = "Deploy user";
        extraGroups = ["wheel"];
        openssh.authorizedKeys.keys = self.keys-admin;
      };
    };

    deploy.nodes.homelab = {
      hostname = "homelab";
      sshUser = "deploy";

      profiles.system = {
        user = "root";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.homelab;
      };
    };
  };

  perSystem = {
    pkgs,
    system,
    ...
  }: {
    packages.deploy-rs = pkgs.deploy-rs;

    apps.deploy = {
      type = "app";
      program = "${pkgs.deploy-rs}/bin/deploy";
    };

    checks =
      if pkgs.stdenv.isLinux
      then inputs.deploy-rs.lib.${system}.deployChecks self.deploy
      else {};
  };
}
