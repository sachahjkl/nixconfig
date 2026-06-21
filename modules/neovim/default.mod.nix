_: {
  flake.nixosModules.neovim = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    editor = lib.attrByPath ["editor"] {} config;
    enabled = lib.attrByPath ["neovim" "enable"] false editor || lib.attrByPath ["default"] "neovim" editor == "neovim";
    initLua = pkgs.writeText "init.lua" (
      lib.replaceStrings
      [
        "@lazy_nvim@"
        "@gruvbox_nvim@"
        "@fff_nvim@"
        "@oil_nvim@"
        "@which_key_nvim@"
        "@nvim_web_devicons@"
        "@nvim_lspconfig@"
        "@mason_nvim@"
        "@mason_lspconfig_nvim@"
        "@mason_tool_installer_nvim@"
        "@blink_cmp@"
        "@friendly_snippets@"
        "@roslyn_nvim@"
      ]
      [
        "${pkgs.vimPlugins."lazy-nvim"}"
        "${pkgs.vimPlugins."gruvbox-nvim"}"
        "${pkgs.vimPlugins."fff-nvim"}"
        "${pkgs.vimPlugins."oil-nvim"}"
        "${pkgs.vimPlugins."which-key-nvim"}"
        "${pkgs.vimPlugins.nvim-web-devicons}"
        "${pkgs.vimPlugins."nvim-lspconfig"}"
        "${pkgs.vimPlugins."mason-nvim"}"
        "${pkgs.vimPlugins."mason-lspconfig-nvim"}"
        "${pkgs.vimPlugins."mason-tool-installer-nvim"}"
        "${pkgs.vimPlugins."blink-cmp"}"
        "${pkgs.vimPlugins."friendly-snippets"}"
        "${pkgs.vimPlugins."roslyn-nvim"}"
      ]
      (builtins.readFile ./init.lua.in)
    );
    hasHjemUsers = lib.hasAttrByPath ["hjem" "users"] options;
    hasPreservationDirs = lib.hasAttrByPath ["persist" "user" "directories"] options;
    hasUserName = lib.hasAttrByPath ["userName"] options;
  in {
    config = lib.mkIf enabled (lib.mkMerge [
      {
        environment.systemPackages = with pkgs; [
          dotnet-sdk
          neovim
          nodejs
          wl-clipboard
          xclip
        ];
      }

      (lib.optionalAttrs hasPreservationDirs {
        persist.user.directories = [
          ".cache/nvim"
          ".config/nvim"
          ".local/share/nvim"
          ".local/state/nvim"
        ];
      })

      (lib.optionalAttrs (hasHjemUsers && hasUserName) {
        hjem.users.${config.userName}.xdg.config.files."nvim/init.lua".source = initLua;
      })
    ]);
  };
}
