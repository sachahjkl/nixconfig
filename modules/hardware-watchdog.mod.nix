_: {
  flake.nixosModules.hardwareWatchdog = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkEnableOption mkOption types;
    cfg = config.services.hardwareWatchdog;
  in {
    options.services.hardwareWatchdog = {
      enable = mkEnableOption "the systemd hardware watchdog";

      timeout = mkOption {
        type = types.str;
        default = "60s";
        description = "Interval in which systemd must ping the hardware watchdog. The watchdog resets the machine when this interval passes without a ping.";
      };

      rebootTimeout = mkOption {
        type = types.str;
        default = "10min";
        description = "Hardware watchdog timeout for the final phase of a directed reboot.";
      };
    };

    config = lib.mkIf cfg.enable {
      systemd.settings.Manager = {
        RuntimeWatchdogSec = cfg.timeout;
        RebootWatchdogSec = cfg.rebootTimeout;
      };
    };
  };
}
