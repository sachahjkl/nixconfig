{self, ...}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: let
    meshcentralCli = pkgs.writeShellApplication {
      name = "meshcentral";
      runtimeInputs = [pkgs.coreutils];
      text = ''
        data_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/meshcentral"
        mkdir -p "$data_dir"

        exec ${lib.getExe pkgs.meshcentral} \
          --datapath "$data_dir" \
          --port 4443 \
          --redirport 4080 \
          "$@"
      '';
    };

    meshcentralLaunch = pkgs.writeShellApplication {
      name = "meshcentral-launch";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.curl
        pkgs.xdg-utils
      ];
      text = ''
        cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/meshcentral"
        mkdir -p "$cache_dir"

        if ! ${lib.getExe pkgs.curl} --silent --insecure --max-time 2 https://127.0.0.1:4443 >/dev/null; then
          nohup ${lib.getExe meshcentralCli} >>"$cache_dir/server.log" 2>&1 &
          sleep 2
        fi

        exec ${lib.getExe' pkgs.xdg-utils "xdg-open"} https://127.0.0.1:4443
      '';
    };

    meshcentralDesktop = pkgs.makeDesktopItem {
      name = "meshcentral";
      desktopName = "MeshCentral";
      comment = "Intel AMT and remote management portal";
      exec = "meshcentral-launch";
      terminal = false;
      categories = ["Network" "RemoteAccess" "System"];
      keywords = [
        "AMT"
        "Intel"
        "KVM"
        "MeshCentral"
        "Remote Desktop"
        "Remote Management"
      ];
      startupNotify = true;
    };
  in {
    packages.meshcentral = pkgs.symlinkJoin {
      name = "meshcentral-wrapped";
      paths = [
        meshcentralCli
        meshcentralLaunch
        meshcentralDesktop
      ];
    };
  };

  flake.nixosModules.meshcentral = {pkgs, ...}: let
    selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
  in {
    preferences.preservation.user.directories = [
      ".cache/meshcentral"
      ".local/share/meshcentral"
    ];

    environment.systemPackages = [selfPkgs.meshcentral];
  };
}
