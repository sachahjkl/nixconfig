{self, ...}: {
  flake.nixosModules.packages = {
    config,
    pkgs,
    ...
  }: let
    selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
  in {
    imports = [self.nixosModules.git];

    config = {
      programs = {
        bat.enable = true;
        htop.enable = true;
        nh = {
          enable = true;
          package = selfPkgs.nh;
          flake = config.nixConfigPath;
        };
        tmux.enable = true;
      };

      environment.systemPackages = with pkgs; [
        # Shell
        selfPkgs.userShell

        # Security
        age

        # Core utilities
        bc
        coreutils
        file
        findutils
        gnutar
        gzip
        gnugrep
        gnused
        less
        moreutils
        rename
        tree
        unzip
        which
        xz
        zstd
        zip

        # Shell and editor helpers
        btop
        carapace
        difftastic
        eza
        fd
        jq
        ripgrep
        ufetch
        zellij

        # Networking and remote access
        curl
        selfPkgs.deploy-rs
        dnsutils
        inetutils
        iproute2
        iputils
        mtr
        netcat-openbsd
        openssh
        rsync
        traceroute
        wget
        whois
        meshcentral # homelab AMT remote access

        # System administration and inspection
        cronie
        glibc
        lsb-release
        lsof
        pciutils
        plocate
        procps
        psmisc
        pstree
        pv
        usbutils

        # Documentation and diagnostics
        man-db
        man-pages
        nmap

        # Language tooling
        python3
        uv
      ];
    };
  };
}
