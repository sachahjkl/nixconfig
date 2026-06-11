{self, ...}: {
  perSystem = {pkgs, ...}: let
    version = "0.8.3";
    handyAppImage = pkgs.appimageTools.wrapType2 {
      pname = "handy";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://github.com/cjpais/Handy/releases/download/v${version}/Handy_${version}_amd64.AppImage";
        hash = "sha256-8rQJVpABydLXGlyLNIdw/cilAcmwvmAb93VoaJJ+KJQ=";
      };
    };

    handyPaste = pkgs.writeShellApplication {
      name = "handy-paste";
      runtimeInputs = [pkgs.dotool];
      text = ''
        printf 'type %s\n' "''${1?}" | dotool
      '';
    };

    handyIcon = pkgs.runCommand "handy-icon" {} ''
      mkdir -p "$out/share/icons/hicolor/128x128/apps"
      cp ${pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/cjpais/Handy/main/src-tauri/icons/128x128.png";
        hash = "sha256-1lJ3InGYiQOGLXOxfsYou8J05CN6beBjg0LUPdpY004=";
      }} "$out/share/icons/hicolor/128x128/apps/handy.png"
    '';

    handyDesktop = pkgs.makeDesktopItem {
      name = "handy";
      desktopName = "Handy";
      comment = "Offline speech-to-text transcription";
      exec = "handy";
      icon = "handy";
      terminal = false;
      categories = ["Utility" "AudioVideo"];
      startupNotify = true;
    };

    handySettings = pkgs.writeText "handy-settings-store.json" (builtins.toJSON {
      settings = {
        always_on_microphone = false;
        app_language = "en-US";
        append_trailing_space = false;
        audio_feedback = true;
        audio_feedback_volume = 1.0;
        auto_submit = false;
        auto_submit_key = "enter";
        autostart_enabled = false;
        bindings = {
          cancel = {
            current_binding = "escape";
            default_binding = "escape";
            description = "Cancels the current recording.";
            id = "cancel";
            name = "Cancel";
          };
          transcribe = {
            current_binding = "ctrl+shift+space";
            default_binding = "ctrl+space";
            description = "Converts your speech into text.";
            id = "transcribe";
            name = "Transcribe";
          };
          transcribe_with_post_process = {
            current_binding = "ctrl+shift+space";
            default_binding = "ctrl+shift+space";
            description = "Converts your speech into text and applies AI post-processing.";
            id = "transcribe_with_post_process";
            name = "Transcribe with Post-Processing";
          };
        };
        clamshell_microphone = null;
        clipboard_handling = "dont_modify";
        custom_filler_words = null;
        custom_words = [];
        debug_mode = false;
        experimental_enabled = true;
        external_script_path = null;
        extra_recording_buffer_ms = 0;
        history_limit = 5;
        keyboard_implementation = "tauri";
        lazy_stream_close = true;
        log_level = "debug";
        model_unload_timeout = "min5";
        mute_while_recording = false;
        ort_accelerator = "auto";
        overlay_position = "none";
        paste_delay_ms = 60;
        paste_method = "shift_insert";
        post_process_api_keys = {
          anthropic = "";
          bedrock_mantle = "";
          cerebras = "";
          custom = "";
          groq = "";
          openai = "";
          openrouter = "";
          zai = "";
        };
        post_process_enabled = false;
        post_process_models = {
          anthropic = "";
          bedrock_mantle = "";
          cerebras = "";
          custom = "";
          groq = "";
          openai = "";
          openrouter = "";
          zai = "";
        };
        post_process_prompts = [
          {
            id = "default_improve_transcriptions";
            name = "Improve Transcriptions";
            prompt = "Clean this transcript:\n1. Fix spelling, capitalization, and punctuation errors\n2. Convert number words to digits (twenty-five → 25, ten percent → 10%, five dollars → $5)\n3. Replace spoken punctuation with symbols (period → ., comma → ,, question mark → ?)\n4. Remove filler words (um, uh, like as filler)\n5. Keep the language in the original version (if it was french, keep it in french for example)\n\nPreserve exact meaning and word order. Do not paraphrase or reorder content.\n\nReturn only the cleaned transcript.\n\nTranscript:\n\${output}";
          }
        ];
        post_process_provider_id = "openai";
        post_process_providers = [
          {
            allow_base_url_edit = false;
            base_url = "https://api.openai.com/v1";
            id = "openai";
            label = "OpenAI";
            models_endpoint = "/models";
            supports_structured_output = true;
          }
          {
            allow_base_url_edit = false;
            base_url = "https://api.z.ai/api/paas/v4";
            id = "zai";
            label = "Z.AI";
            models_endpoint = "/models";
            supports_structured_output = true;
          }
          {
            allow_base_url_edit = false;
            base_url = "https://openrouter.ai/api/v1";
            id = "openrouter";
            label = "OpenRouter";
            models_endpoint = "/models";
            supports_structured_output = true;
          }
          {
            allow_base_url_edit = false;
            base_url = "https://api.anthropic.com/v1";
            id = "anthropic";
            label = "Anthropic";
            models_endpoint = "/models";
            supports_structured_output = false;
          }
          {
            allow_base_url_edit = false;
            base_url = "https://api.groq.com/openai/v1";
            id = "groq";
            label = "Groq";
            models_endpoint = "/models";
            supports_structured_output = false;
          }
          {
            allow_base_url_edit = false;
            base_url = "https://api.cerebras.ai/v1";
            id = "cerebras";
            label = "Cerebras";
            models_endpoint = "/models";
            supports_structured_output = true;
          }
          {
            allow_base_url_edit = false;
            base_url = "https://bedrock-mantle.us-east-1.api.aws/v1";
            id = "bedrock_mantle";
            label = "AWS Bedrock (Mantle)";
            models_endpoint = "/models";
            supports_structured_output = true;
          }
          {
            allow_base_url_edit = true;
            base_url = "http://localhost:11434/v1";
            id = "custom";
            label = "Custom";
            models_endpoint = "/models";
            supports_structured_output = false;
          }
        ];
        post_process_selected_prompt_id = null;
        push_to_talk = false;
        recording_retention_period = "preserve_limit";
        selected_language = "auto";
        selected_microphone = null;
        selected_model = "parakeet-tdt-0.6b-v3";
        selected_output_device = null;
        show_tray_icon = true;
        sound_theme = "marimba";
        start_hidden = true;
        translate_to_english = false;
        typing_tool = "auto";
        update_checks_enabled = true;
        whisper_accelerator = "auto";
        whisper_gpu_device = -1;
        word_correction_threshold = 0.18;
      };
    });

    handyPkg = pkgs.symlinkJoin {
      name = "handy-${version}";
      paths = [handyAppImage handyDesktop handyIcon handyPaste];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
                  mv "$out/bin/handy" "$out/bin/.handy-real"
                  cat > "$out/bin/handy" <<'WRAPPER_EOF'
        #!/bin/sh
        set -eu

        app_data_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/com.pais.handy"
        settings_store="''${app_data_dir}/settings_store.json"

        mkdir -p "$app_data_dir"
        if [ ! -e "$settings_store" ]; then
          cp ${handySettings} "$settings_store"
          chmod +w "$settings_store"
        fi

        exec "$(dirname "$0")/.handy-real" "$@"
        WRAPPER_EOF
                  chmod +x "$out/bin/handy"
      '';
    };
  in {
    packages.handy = handyPkg;
  };

  flake.nixosModules.ai = {
    config,
    lib,
    pkgs,
    ...
  }: let
    selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
    cfg = config.features.ai;
  in {
    options.features.ai = {
      enable = lib.mkEnableOption "AI features (speech-to-text, dictation tools)";

      handy.enable = lib.mkOption {
        type = lib.types.bool;
        default = config.features.ai.enable;
        defaultText = lib.literalExpression "config.features.ai.enable";
        description = "Enable Handy offline speech-to-text. Enabled by default when features.ai.enable is true.";
      };
    };

    config = lib.mkMerge [
      (lib.mkIf cfg.enable {
        environment.systemPackages = [pkgs.dotool pkgs.ydotool];

        programs.ydotool.enable = true;

        users.users.${config.userName}.extraGroups = ["input" "ydotool"];

        services.udev.extraRules = ''
          SUBSYSTEM=="misc", KERNEL=="uinput", GROUP="input", MODE="0660"
        '';
      })

      (lib.mkIf (cfg.enable && cfg.handy.enable) {
        environment.systemPackages = [selfPkgs.handy];

        preferences.preservation.user.directories = [
          ".local/share/com.pais.handy"
        ];
      })
    ];
  };
}
