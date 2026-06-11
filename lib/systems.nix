{ inputs, lib, self, ... }:
{
  nixosSystem =
    hostName:
    {
      module,
      system ? "x86_64-linux",
      extraModules ? [ ],
      extraSpecialArgs ? { },
    }:
    {
      flake.nixosConfigurations.${hostName} = lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs self;
          lib = lib;
        } // extraSpecialArgs;

        modules = extraModules ++ [
          module
          {
            networking.hostName = hostName;
          }
        ];
      };
    };
}
