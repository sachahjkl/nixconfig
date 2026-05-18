{ ... }:

{
  flake.nixosModules.secrets = { lib, ... }: {
    options.secrets.userPasswordHash = lib.mkOption {
      type = lib.types.str;
      default = lib.fileContents ./user-password.hash;
      description = "Primary local user password hash.";
    };
  };
}
