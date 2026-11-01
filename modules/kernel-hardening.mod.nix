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
        # CVE-2026-98432 reaches the IPv4 TCP handshake. Multipath TCP listeners
        # are only needed by applications that ask for them, and Go opens them
        # by default since Go 1.24. Nothing here uses MPTCP.
        "net.mptcp.enabled" = 0;
      };

      kernelParams = [
        "randomize_kstack_offset=on"
        "vsyscall=none"
      ];
    };
  };
}
