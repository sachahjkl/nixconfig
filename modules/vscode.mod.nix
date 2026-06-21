_: {
  flake.nixosModules.vscode = {
    config,
    lib,
    pkgs,
    ...
  }: let
    editor = lib.attrByPath ["editor"] {} config;
    enabled = lib.attrByPath ["vscode" "enable"] false editor || lib.attrByPath ["default"] "neovim" editor == "vscode";
  in {
    home-manager.users.${config.userName}.programs.vscode = {
      enable = enabled;
      package = pkgs.vscode;
      mutableExtensionsDir = true;
      profiles.default = {
        enableExtensionUpdateCheck = false;
        enableUpdateCheck = false;
        extensions = with pkgs.vscode-extensions; [
          jdinhlife.gruvbox
          jnoortheen.nix-ide
          ms-dotnettools.csdevkit
          vscode-icons-team.vscode-icons
        ];
        userSettings = {
          "editor.fontFamily" = config.theme.fonts.mono;
          "extensions.autoCheckUpdates" = false;
          "extensions.autoUpdate" = false;
          "files.autoSave" = "afterDelay";
          "git.autofetch" = false;
          "nix.enableLanguageServer" = true;
          "nix.formatterPath" = "alejandra";
          "nix.serverPath" = "nixd";
          "nix.serverSettings" = {
            nixd.formatting.command = ["alejandra"];
          };
          "terminal.integrated.defaultProfile.linux" = "fish";

          "chat.commandCenter.enabled" = false;
          "security.workspace.trust.startupPrompt" = "never";
          "security.workspace.trust.untrustedFiles" = "open";
          "telemetry.enableCrashReporter" = false;
          "telemetry.enableTelemetry" = false;
          "update.enableWindowsBackgroundUpdates" = false;
          "update.channel" = "none";
          "workbench.settings.enableNaturalLanguageSearch" = false;

          "window.autoDetectColorScheme" = true;
          "workbench.colorTheme" = "Gruvbox Dark Hard";
          "workbench.preferredDarkColorTheme" = "Gruvbox Dark Hard";
          "workbench.preferredLightColorTheme" = "Gruvbox Light Hard";
          "workbench.iconTheme" = "vscode-icons";
          "workbench.enableExperiments" = false;
          "workbench.sideBar.location" = "right";
          "workbench.statusBar.feedback.visible" = false;

          "workbench.startupEditor" = "none";
          "workbench.welcomePage.walkthroughs.openOnInstall" = false;
          "workbench.tips.enabled" = false;
          "update.showReleaseNotes" = false;
        };
      };
    };

    persist.user.directories = lib.mkIf enabled [".config/Code"];
  };
}
