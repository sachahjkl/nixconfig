_: {
  flake.nixosModules.thermalGuard = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) escapeShellArg mkEnableOption mkOption types;
    cfg = config.services.thermalGuard;
  in {
    options.services.thermalGuard = {
      enable = mkEnableOption "CPU temperature surveillance";

      chip = mkOption {
        type = types.str;
        default = "coretemp";
        description = "Name of the hwmon chip to read, as listed in /sys/class/hwmon/*/name.";
      };

      sensor = mkOption {
        type = types.str;
        default = "temp1_input";
        description = "hwmon attribute that reports a temperature in millidegrees Celsius.";
      };

      intervalSeconds = mkOption {
        type = types.ints.positive;
        default = 30;
        description = "Delay between two temperature samples.";
      };

      reportIntervalSeconds = mkOption {
        type = types.ints.positive;
        default = 300;
        description = "Delay between two journal reports while the temperature stays below warnCelsius.";
      };

      warnCelsius = mkOption {
        type = types.ints.unsigned;
        default = 85;
        description = "Temperature that logs a warning to the journal.";
      };

      criticalCelsius = mkOption {
        type = types.ints.unsigned;
        default = 97;
        description = "Temperature that triggers criticalAction.";
      };

      criticalAction = mkOption {
        type = types.enum ["log" "poweroff"];
        default = "log";
        description = "Action when the temperature reaches criticalCelsius.";
      };
    };

    config = lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.warnCelsius < cfg.criticalCelsius;
          message = "services.thermalGuard.warnCelsius must stay below services.thermalGuard.criticalCelsius.";
        }
      ];

      systemd.services.thermal-guard = {
        description = "CPU temperature surveillance";
        wantedBy = ["multi-user.target"];
        after = ["local-fs.target"];
        path = [pkgs.bash pkgs.coreutils pkgs.systemd];

        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = 10;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
        };

        script = ''
          set -euo pipefail

          chip=${escapeShellArg cfg.chip}
          sensor=${escapeShellArg cfg.sensor}
          action=${escapeShellArg cfg.criticalAction}
          warn=${toString cfg.warnCelsius}
          critical=${toString cfg.criticalCelsius}
          interval=${toString cfg.intervalSeconds}
          reportInterval=${toString cfg.reportIntervalSeconds}

          log() {
            local priority=$1
            shift
            printf '%s\n' "$*" | systemd-cat -t thermal-guard -p "$priority"
          }

          readTemperature() {
            local directory
            for directory in /sys/class/hwmon/hwmon*; do
              [ -r "$directory/name" ] || continue
              if [ "$(cat "$directory/name")" = "$chip" ]; then
                cat "$directory/$sensor"
                return 0
              fi
            done
            return 1
          }

          state=""
          lastReport=0

          while true; do
            if ! reading=$(readTemperature); then
              log err "chip=$chip sensor=$sensor not found"
              sleep "$interval"
              continue
            fi

            celsius=$(( reading / 1000 ))

            if [ "$celsius" -ge "$critical" ]; then
              next="critical"
            elif [ "$celsius" -ge "$warn" ]; then
              next="warning"
            else
              next="ok"
            fi

            now=$SECONDS
            if [ "$next" != "$state" ] || [ $(( now - lastReport )) -ge "$reportInterval" ]; then
              message="chip=$chip sensor=$sensor celsius=$celsius state=$next warn=$warn critical=$critical"
              case "$next" in
                critical) log err "$message" ;;
                warning) log warning "$message" ;;
                *) log info "$message" ;;
              esac
              lastReport=$now
            fi

            if [ "$next" = "critical" ] && [ "$action" = "poweroff" ]; then
              log err "celsius=$celsius reached critical=$critical, powering off"
              systemctl poweroff
            fi

            state=$next
            sleep "$interval"
          done
        '';
      };
    };
  };
}
