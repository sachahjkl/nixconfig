{ ... }:

{
  flake.nixosModules.vscode = { config, pkgs, ... }: {
      home-manager.users.${config.userName}.programs.vscode = {
        enable = true;
        package = pkgs.vscode;
        profiles.default = {
          extensions = with pkgs.vscode-extensions; [
            jdinhlife.gruvbox
            vscode-icons-team.vscode-icons
          ];
          userSettings = {
            "editor.fontFamily" = config.preferences.theme.fonts.mono;
            "extensions.autoCheckUpdates" = false;
            "extensions.autoUpdate" = false;
            "files.autoSave" = "afterDelay";
            "git.autofetch" = false;
            "nix.enableLanguageServer" = true;
            "nix.formatterPath" = "alejandra";
            "nix.serverPath" = "nixd";
            "nix.serverSettings" = {
              nixd.formatting.command = [ "alejandra" ];
            };
            "terminal.integrated.defaultProfile.linux" = "fish";

            "chat.commandCenter.enabled" = false;
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
            "workbench.statusBar.feedback.visible" = false;

            "workbench.startupEditor" = "none";
            "workbench.welcomePage.walkthroughs.openOnInstall" = false;
            "workbench.tips.enabled" = false;
            "update.showReleaseNotes" = false;
          };
        };
      };

      preferences.preservation.user.directories = [ ".config/Code" ];
    };
}
