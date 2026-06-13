{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.deployUser = {
    users.users.deploy = {
      isNormalUser = true;
      description = "Deploy user";
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = [self.keys.admin];
    };
  };

  flake.deploy.nodes.homelab = {
    hostname = "homelab";
    sshUser = "deploy";

    profiles.system = {
      user = "root";
      path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.homelab;
    };
  };

  perSystem = {
    pkgs,
    system,
    ...
  }: {
    packages.deploy-rs = inputs.deploy-rs.packages.${system}.default;

    apps.deploy = {
      type = "app";
      program = "${inputs.deploy-rs.packages.${system}.default}/bin/deploy";
    };

    checks =
      if pkgs.stdenv.isLinux
      then inputs.deploy-rs.lib.${system}.deployChecks self.deploy
      else {};
  };
}
