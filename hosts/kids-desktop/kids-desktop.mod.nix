{
  self,
  lib,
  ...
}:
lib.systems.nixosSystem "kids-desktop" {
  module = {
    imports = [
      self.diskoConfigurations.kids-desktop
      self.nixosModules.disko
      self.nixosModules.kidsDesktop
      self.nixosModules.kids-desktop-hardware
    ];

    kidsDesktop.accounts.children = {
      juliette = {
        fullName = "Juliette";
        passwordHash = "$y$j9T$jfubAigMbDJM5rFyLHemt/$pyFHNX/Ju9MubmMl3gQLXdL9CCvsjP741ZENgEitmCA";
      };
      pierre = {
        fullName = "Pierre";
        passwordHash = "$y$j9T$5cZHLfXrITNHEBo2kbbSc1$6a8ILJuiOW0Js9asFcwZASN7JGQ6EI1AJMZbVTpKd7D";
      };
    };

    system.autoUpgrade = {
      enable = false;
      flake = "/etc/nixos#kids-desktop";
    };
  };
}
