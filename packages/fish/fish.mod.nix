{
  inputs,
  lib,
  self,
  ...
}: {
  flake.nixosModules.fish = {
    config,
    pkgs,
    ...
  }: let
    fishPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.fish;
  in {
    persist.user.directories = [".local/share/fish"];

    programs.fish = {
      enable = true;
      # Carapace provides completions without rebuilding one derivation per system package.
      generateCompletions = false;
      package = fishPackage;
      shellAliases = {
        ls = "eza";
        vim = "nvim";
      };
    };

    hjem.users.${config.userName}.rum.programs = {
      fish = {
        enable = true;
        package = null;
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
        flags = ["--cmd cd"];
        integrations.fish.enable = true;
      };
    };

    programs.starship.enable = true;
  };

  perSystem = {
    pkgs,
    self',
    ...
  }: {
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
