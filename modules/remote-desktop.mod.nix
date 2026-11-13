{self, ...}: {
  # Remote desktop, reached from the local network and Tailscale only:
  # - wayvnc: the Wayland session in use (ShojiWM, Hyprland), over VNC with
  #   RSA-AES encryption and a password. A user service of the graphical
  #   session: it starts and stops with it.
  # - voxl: a desktop of its own (XFCE on a virtual X display), in a browser
  #   over HTTPS with a password. System services, up from boot, with no
  #   session needed.
  # The passwords are SOPS secrets (secrets/shared.yaml, remote-desktop/*).
  flake.nixosModules.remoteDesktop = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.remoteDesktop;
    inherit (config) userName;
    sopsFile = builtins.path {
      path = self + /secrets/shared.yaml;
      name = "shared-secrets.yaml";
    };
    secret = {
      inherit sopsFile;
      owner = userName;
      group = "users";
      mode = "0400";
    };
    selfPackages = self.packages.${pkgs.stdenv.hostPlatform.system};
    home = config.users.users.${userName}.home;

    # The configuration holds the password, so it is written at each start
    # into the runtime folder (a tmpfs, mode 0700), never into the store.
    wayvncStart = pkgs.writeShellScript "wayvnc-start" ''
      set -eu
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/wayvnc"
      run="$XDG_RUNTIME_DIR/wayvnc"
      mkdir -p "$state" "$run"
      chmod 700 "$state" "$run"
      # The server's key for RSA-AES (TigerVNC, RealVNC): made once and kept,
      # so a client that trusted it is not asked again.
      if [ ! -s "$state/rsa_key.pem" ]; then
        ${pkgs.openssh}/bin/ssh-keygen -q -m pem -t rsa -b 3072 -N "" -f "$state/rsa_key.pem"
      fi
      umask 077
      {
        echo "address=0.0.0.0"
        echo "port=${toString cfg.wayvnc.port}"
        echo "enable_auth=true"
        echo "username=${userName}"
        printf 'password=%s\n' "$(cat ${config.sops.secrets."remote-desktop/wayvnc-password".path})"
        echo "rsa_private_key_file=$state/rsa_key.pem"
      } > "$run/config"
      exec ${lib.getExe pkgs.wayvnc} --config="$run/config"
    '';

    xfce = with pkgs; [
      xfce4-session
      xfwm4
      xfce4-panel
      xfdesktop
      xfce4-settings
      xfconf
      thunar
      xfce4-terminal
      adwaita-icon-theme
    ];
    # What the voxl desktop's programs find: the system's, then XFCE's.
    voxlEnvironment = {
      DISPLAY = cfg.voxl.display;
      HOME = home;
      XDG_CURRENT_DESKTOP = "XFCE";
      XDG_DATA_DIRS = "/run/current-system/sw/share";
      XDG_CONFIG_DIRS = "/etc/xdg:/run/current-system/sw/etc/xdg";
    };
    displayNumber = lib.removePrefix ":" cfg.voxl.display;
    waitForDisplay = pkgs.writeShellScript "voxl-wait-for-display" ''
      # Xvfb makes its socket once it takes clients: wait for it, 15 s at most.
      for _ in $(seq 1 150); do
        [ -S /tmp/.X11-unix/X${displayNumber} ] && exit 0
        sleep 0.1
      done
      echo "no X display ${cfg.voxl.display} after 15 s" >&2
      exit 1
    '';
    restart = {
      Restart = "always";
      RestartSec = 3;
    };
  in {
    options.remoteDesktop = {
      lanInterfaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["enp10s0"];
        description = "Local network interfaces the remote desktops listen on, besides Tailscale (a trusted interface already).";
      };

      wayvnc = {
        enable = lib.mkEnableOption "wayvnc for the Wayland session in use (VNC, RSA-AES, password from the remote-desktop/wayvnc-password secret)";
        port = lib.mkOption {
          type = lib.types.port;
          default = 5900;
        };
      };

      voxl = {
        enable = lib.mkEnableOption "voxl: an XFCE desktop of its own in the browser (HTTPS, password from the remote-desktop/voxl-password secret)";
        port = lib.mkOption {
          type = lib.types.port;
          default = 6901;
        };
        display = lib.mkOption {
          type = lib.types.str;
          default = ":99";
          description = "The virtual X display of the voxl desktop.";
        };
        size = lib.mkOption {
          type = lib.types.str;
          default = "1920x1080";
          description = "The size of the voxl desktop.";
        };
        hostNames = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [config.networking.hostName];
          description = "Host names voxl answers for besides IP addresses (--allowed-hosts), such as the Tailscale name.";
        };
      };
    };

    config = lib.mkMerge [
      (lib.mkIf (cfg.wayvnc.enable || cfg.voxl.enable) {
        networking.firewall.interfaces = lib.genAttrs cfg.lanInterfaces (_: {
          allowedTCPPorts =
            lib.optional cfg.wayvnc.enable cfg.wayvnc.port
            ++ lib.optional cfg.voxl.enable cfg.voxl.port;
        });
      })

      (lib.mkIf cfg.wayvnc.enable {
        sops.secrets."remote-desktop/wayvnc-password" = secret;
        persist.user.directories = [".local/state/wayvnc"];
        environment.systemPackages = [pkgs.wayvnc];

        systemd.user.services.wayvnc = {
          description = "wayvnc, the Wayland session over VNC";
          wantedBy = ["graphical-session.target"];
          partOf = ["graphical-session.target"];
          after = ["graphical-session.target"];
          unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
          serviceConfig = {
            ExecStart = wayvncStart;
            Restart = "on-failure";
            RestartSec = 3;
          };
        };
      })

      (lib.mkIf cfg.voxl.enable {
        sops = {
          secrets."remote-desktop/voxl-password" = secret;
          templates."voxl.env" = {
            owner = userName;
            mode = "0400";
            content = ''
              VOXL_PASSWORD=${config.sops.placeholder."remote-desktop/voxl-password"}
            '';
          };
        };
        # The desktop's own settings, and voxl's self-signed certificate,
        # which browsers then trust once.
        persist = {
          user.directories = [".config/xfce4"];
          system.directories = [
            {
              directory = "/var/lib/voxl";
              user = userName;
              group = "users";
              mode = "0700";
            }
          ];
        };
        environment.systemPackages = xfce ++ [selfPackages.voxl];

        systemd.services = {
          voxl-display = {
            description = "The virtual X display of the voxl desktop";
            wantedBy = ["multi-user.target"];
            serviceConfig =
              {
                User = userName;
                Group = "users";
                ExecStart = "${selfPackages.voxl-xvfb}/bin/Xvfb ${cfg.voxl.display} -screen 0 ${cfg.voxl.size}x24 -shmem -nolisten tcp -dpi 96";
                ExecStartPost = waitForDisplay;
              }
              // restart;
          };

          voxl-desktop = {
            description = "The XFCE desktop of voxl";
            wantedBy = ["multi-user.target"];
            bindsTo = ["voxl-display.service"];
            after = ["voxl-display.service"];
            environment = voxlEnvironment;
            # A session bus of its own: the user's graphical session keeps its
            # own, and the two desktops' programs do not meet.
            serviceConfig =
              {
                User = userName;
                Group = "users";
                ExecStart = "${pkgs.dbus}/bin/dbus-run-session -- ${pkgs.xfce4-session}/bin/xfce4-session";
              }
              // restart;
            path = xfce ++ ["/run/current-system/sw"];
          };

          voxl = {
            description = "voxl, the voxl desktop in a browser";
            wantedBy = ["multi-user.target"];
            bindsTo = ["voxl-display.service"];
            after = ["voxl-display.service" "network.target"];
            environment =
              voxlEnvironment
              // {
                VOXL_TLS_DIR = "/var/lib/voxl";
              };
            serviceConfig =
              {
                User = userName;
                Group = "users";
                EnvironmentFile = config.sops.templates."voxl.env".path;
                ExecStart = lib.concatStringsSep " " [
                  (lib.getExe selfPackages.voxl)
                  "--addr=0.0.0.0"
                  "--port=${toString cfg.voxl.port}"
                  "--tls"
                  "--allowed-hosts=${lib.concatStringsSep "," cfg.voxl.hostNames}"
                  # The sound would be the user's session's, not this desktop's.
                  "--audio-enabled=false"
                  "--microphone-enabled=false"
                ];
              }
              // restart;
          };
        };
      })
    ];
  };
}
