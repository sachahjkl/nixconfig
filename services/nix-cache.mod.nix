{self, ...}: {
  flake.nixosModules.nixCache = {
    config,
    pkgs,
    ...
  }: let
    dashboardPage = builtins.path {
      path = ./nix-cache/dashboard.html;
      name = "nix-cache-dashboard.html";
    };
    dashboardFiles = pkgs.runCommand "nix-cache-dashboard" {} ''
      install -Dm444 ${dashboardPage} $out/index.html
    '';
    dashboardRoot = "/run/nix-cache-dashboard";
    secretName = "nix-cache/signing-key";
  in {
    imports = [self.nixosModules.sops];

    sops.secrets.${secretName} = {
      sopsFile = self + /secrets/homelab.yaml;
      owner = "root";
      group = "root";
      mode = "0400";
    };

    services.nix-serve = {
      enable = true;
      bindAddress = "127.0.0.1";
      package = pkgs.nix-serve-ng;
      port = 5000;
      secretKeyFile = config.sops.secrets.${secretName}.path;
    };

    systemd = {
      services.nix-cache-dashboard = {
        description = "Update the Nix cache dashboard status";
        after = ["nix-serve.service"];
        wantedBy = ["multi-user.target"];
        path = [pkgs.coreutils pkgs.jq pkgs.systemd];
        serviceConfig.Type = "oneshot";
        script = ''
          set -euo pipefail
          install -d -m 0755 ${dashboardRoot}
          ln -sfn ${dashboardFiles}/index.html ${dashboardRoot}/index.html

          read -r total used available percent < <(
            df --block-size=1 --output=size,used,avail,pcent /nix | tail -n 1
          )
          service_status="$(systemctl is-active nix-serve.service || true)"

          jq -n \
            --arg service "$service_status" \
            --arg usedPercent "$percent" \
            --arg updatedAt "$(date --iso-8601=seconds)" \
            --argjson totalBytes "$total" \
            --argjson usedBytes "$used" \
            --argjson availableBytes "$available" \
            '{
              $service,
              $usedPercent,
              $updatedAt,
              $totalBytes,
              $usedBytes,
              $availableBytes
            }' > ${dashboardRoot}/status.json.tmp

          mv ${dashboardRoot}/status.json.tmp ${dashboardRoot}/status.json
          chmod 0644 ${dashboardRoot}/status.json
        '';
      };

      services.nix-cache-dashboard-server = {
        description = "Serve the Nix cache dashboard to Traefik";
        requires = ["nix-cache-dashboard.service"];
        after = ["nix-cache-dashboard.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          DynamicUser = true;
          ExecStart = "${pkgs.python3}/bin/python -m http.server 5001 --bind 127.0.0.1 --directory ${dashboardRoot}";
          Restart = "on-failure";
        };
      };

      timers.nix-cache-dashboard = {
        description = "Refresh the Nix cache dashboard status";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitActiveSec = "5min";
          Unit = "nix-cache-dashboard.service";
        };
      };
    };
  };
}
