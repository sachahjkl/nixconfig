{self, ...}: {
  flake = {
    keys = {
      # Primary YubiKey-backed admin/login key.
      "yubikey-5-nfc" = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIIS8pndI4CDOvRT+oxhcluB3+N4TIOg8GTdVIHyKgZqsAAAABHNzaDo= ssh:";
      "far-from-home" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDflKOeWQ7YWH3dNnebAnLxED1UsoJiUuVx7Ew0DPY/SGwqPpNnt/jfmhpnf7mlmBjBKk28YQFeD0TYenPXb5ph6i3TOhvHXi9hWwBeH4At/dpqZWE+o7wvCOFNSTKG5w/3UlKkd0AeG6rAq6vQyd6otXY+0YcL1utJoBUft7selKCI6t1u3x0f4dzC//knMWJAWJXixwdNZdGe3nWFjWR7Ql3hvlMq6MYAVGmBxb6+dEeM/c004sXFpAwG/AJvlGeAPYUUHiuR3+au2BVvFuisgLKgwbykdRMvm6WrnfvZBmLieFGbZ0DVBTre1t1bpAjM7kRW2uKFB0jeMhH8a2B7TA57gf+VgAan2xtXlEMqLjQPXad/VAaw1p9YPMfVsuBZyhzlrB2ZB/7dJXa8Zt+3p3wk+wRnYXH2iW9+I982ERA180DIpOqV/ASbvxwZAtRkWezl1rXP33N8zy+ui22HmruJj+MlizAuKKT9bPD8QRzhCtTnGG6rAjdWvsIdL1MBhQcF6Hwl/4VFDtlWrVrkPods5WcO0uQaTRf50WITKx9JI/xWtdYZMrbPJ2b2oQ9GHGX7unl4AfPEZvK021FyT13cQHb3NTSLRzHkECW9xlzdT93FS/5pfs5DOQrdDznzlIg72DMNLufVsPUCPumPVoPMBBZqCyOiD1cv8xZYRQ== far-from-home@sacha.house";
      "homelab-ed25519" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICStLWxJjCnM2RWCu/9kgDb5nEIOBVVvig8lPTKnzhkb sacha@homelab 2026-06-04";

      house-desktop = self.keys."yubikey-5-nfc";
      house-laptop = self.keys."yubikey-5-nfc";
      homelab = self.keys."far-from-home";
      wsl = self.keys."far-from-home";
    };

    keys-admin = [
      self.keys."yubikey-5-nfc"
      self.keys."far-from-home"
      self.keys."homelab-ed25519"
    ];
  };
}
