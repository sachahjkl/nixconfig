{lib, ...}: {
  flake.nixosModules.fish = {
    config,
    pkgs,
    ...
  }: {
    persist.user.directories = [".local/share/fish"];

    programs = {
      fish = {
        enable = true;
        # Carapace provides completions without rebuilding one derivation per system package.
        generateCompletions = false;
        shellAliases = {
          ls = "eza";
          vim = "nvim";
        };
      };

      starship.enable = true;
    };

    users.users.${config.userName}.shell = pkgs.fish;

    environment.systemPackages = [pkgs.carapace];

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
  };
}
