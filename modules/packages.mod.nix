{self, ...}: {
  flake.nixosModules.packages = {
    config,
    pkgs,
    ...
  }: let
    selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
  in {
    imports = [
      self.nixosModules.bat
      self.nixosModules.gh
      self.nixosModules.git
      self.nixosModules.golang
      self.nixosModules.hunk
      self.nixosModules.meshcentral
      self.nixosModules.nodejs
      self.nixosModules.tmux
    ];

    config = {
      programs = {
        htop.enable = true;
        nh = {
          enable = true;
          package = selfPkgs.nh;
          flake = config.nixConfigPath;
        };
      };

      environment.systemPackages = with pkgs; [
        # Security
        age
        sops

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
        broot
        btop
        chafa
        direnv
        eza
        fastfetch
        fd
        hexyl
        jq
        selfPkgs.lf
        pcre2
        procs
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

        # System administration and inspection
        cronie
        glibc
        lsb-release
        lsof
        pciutils
        plocate
        procps
        psmisc
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
