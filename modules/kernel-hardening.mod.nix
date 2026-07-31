_: {
  flake.nixosModules.kernelHardening = {
    boot = {
      kernel.sysctl = {
        "kernel.sysrq" = 0;
        "kernel.kptr_restrict" = 2;
        "kernel.dmesg_restrict" = 1;
        "fs.protected_fifos" = 2;
        "fs.protected_regular" = 2;
        "fs.suid_dumpable" = 0;
        "kernel.perf_event_paranoid" = 3;
        "kernel.unprivileged_bpf_disabled" = 1;
      };

      kernelParams = [
        "randomize_kstack_offset=on"
        "vsyscall=none"
      ];
    };
  };
}
