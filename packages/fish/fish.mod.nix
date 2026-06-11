{ inputs
, lib
, ...
}:

{
  flake.nixosModules.fish = { config, pkgs, ... }: {
      preferences.preservation.user.directories = [ ".local/share/fish" ];

      programs.fish = {
        enable = true;
      };

      hjem.users.${config.userName}.rum.programs = {
        fish = {
          enable = true;
          package = null;
          aliases.vim = "nvim";
          config = ''
            set fish_greeting
            fish_vi_key_bindings

            ${lib.getExe pkgs.carapace} _carapace fish | source
          '';
          functions.lf = ''
            cd "$(command lf -print-last-dir $argv)"
          '';
        };

        fzf = {
          enable = true;
          integrations.fish.enable = true;
        };

        zoxide = {
          enable = true;
          flags = [ "--cmd cd" ];
          integrations.fish.enable = true;
        };
      };

      programs.starship.enable = true;
    };

  perSystem = { pkgs, self', ... }: {
    packages = {
      fish = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.fish;
        runtimeInputs = with pkgs; [
          self'.packages.lf
          bat
          broot
          carapace
          chafa
          direnv
          eza
          fd
          file
          fzf
          hexyl
          pcre2
          procs
          procps
          ripgrep
          starship
          zoxide
        ];
      };
    };
  };
}
