_: {
  flake.nixosModules.mimeapps = {
    config,
    lib,
    pkgs,
    ...
  }: let
    user = config.userName;
    editorExec = "${config.editor.id}-editor";
    editorDesktop = ''
      [Desktop Entry]
      Name=Editor (${config.editor.id})
      Comment=Edit files with the current editor
      TryExec=${editorExec}
      Exec=${editorExec} %F
      Type=Application
      Terminal=false
      Icon=${config.editor.icon}
      Categories=Utility;TextEditor;
      MimeType=text/plain;text/markdown;text/xml;text/x-python;text/x-script.python;text/x-shellscript;application/json;application/toml;application/x-shellscript;
      StartupNotify=true
    '';

    # Each program, and the types it opens by default.
    defaults = {
      "default-editor.desktop" = [
        "application/json"
        "application/toml"
        "application/x-shellscript"
        "text/markdown"
        "text/plain"
        "text/x-python"
        "text/x-script.python"
        "text/x-shellscript"
        "text/xml"
      ];
      "chromium-browser.desktop" = [
        "application/xhtml+xml"
        "text/html"
        "x-scheme-handler/chrome"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      "classeur.desktop" = ["inode/directory"];
      "org.gnome.gThumb.desktop" = [
        "image/avif"
        "image/bmp"
        "image/gif"
        "image/heic"
        "image/jpeg"
        "image/png"
        "image/svg+xml"
        "image/tiff"
        "image/webp"
        "image/x-icon"
      ];
      # Media Player Classic's look on mpv: it starts as fast as mpv.
      "io.github.mpc_qt.mpc-qt.desktop" = [
        "audio/aac"
        "audio/flac"
        "audio/mp4"
        "audio/mpeg"
        "audio/ogg"
        "audio/opus"
        "audio/wav"
        "audio/webm"
        "audio/x-flac"
        "audio/x-m4a"
        "audio/x-matroska"
        "audio/x-wav"
        "video/mp2t"
        "video/mp4"
        "video/mpeg"
        "video/ogg"
        "video/quicktime"
        "video/webm"
        "video/x-flv"
        "video/x-matroska"
        "video/x-msvideo"
        "video/x-ms-wmv"
      ];
      # A small, fast reader with tabs, as SumatraPDF is.
      "qpdfview.desktop" = [
        "application/pdf"
        "application/postscript"
        "image/vnd.djvu"
      ];
      "org.gnome.FileRoller.desktop" = [
        "application/gzip"
        "application/vnd.rar"
        "application/x-7z-compressed"
        "application/x-bzip2"
        "application/x-compressed-tar"
        "application/x-rar"
        "application/x-tar"
        "application/x-xz"
        "application/x-xz-compressed-tar"
        "application/zip"
        "application/zstd"
      ];
    };
  in {
    # System defaults (/etc/xdg/mimeapps.list). ~/.config/mimeapps.list stays
    # the user's own file: a choice made there, by xdg-mime or a desktop's
    # Default Programs page, comes first.
    xdg.mime.defaultApplications = lib.foldlAttrs (acc: app: types: acc // lib.genAttrs types (_: app)) {} defaults;

    environment.systemPackages = with pkgs; [
      file-roller
      gthumb
      mpc-qt
      qpdfview
    ];

    hjem.users.${user}.files.".local/share/applications/default-editor.desktop".text = editorDesktop;

    system.activationScripts.removeLegacyEditorDesktop.text = ''
      rm -f ${config.homeDirectory}/.local/share/applications/kitty-nvim.desktop
      rm -f ${config.homeDirectory}/.local/share/applications/default-editor.desktop~
    '';
  };
}
