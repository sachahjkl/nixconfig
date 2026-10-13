_: {
  flake.nixosModules.k3sPlatform = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    cfg = config.services.k3sPlatform;
    hasPersistDirs = lib.hasAttrByPath ["persist" "system" "directories"] options;
    hasUserName = lib.hasAttrByPath ["userName"] options;
    kubeconfig = "/etc/rancher/k3s/k3s.yaml";
    podLogs = "/var/log/pods";

    # The bundled Traefik stays inside the cluster: the host Traefik terminates TLS and
    # forwards to this NodePort, which kube-proxy only exposes on the loopback address.
    traefikConfig = {
      apiVersion = "helm.cattle.io/v1";
      kind = "HelmChartConfig";
      metadata = {
        name = "traefik";
        namespace = "kube-system";
      };
      spec.valuesContent = builtins.toJSON {
        service.type = "NodePort";
        ports = {
          web.nodePort = cfg.ingressPort;
          websecure.expose.default = false;
        };
      };
    };
  in {
    options.services.k3sPlatform = {
      enable = lib.mkEnableOption "single-node k3s cluster";

      dataDir = lib.mkOption {
        type = lib.types.str;
        description = "Persistent directory holding k3s state, images, kubelet data, pod logs, and volumes.";
      };

      apiAddress = lib.mkOption {
        type = lib.types.str;
        description = "Private address added to the API server certificate, used by remote kubeconfigs.";
      };

      apiInterface = lib.mkOption {
        type = lib.types.str;
        description = "Private interface that accepts Kubernetes API traffic.";
      };

      ingressPort = lib.mkOption {
        type = lib.types.port;
        default = 30080;
        description = "Loopback NodePort of the in-cluster ingress, used as the host proxy upstream.";
      };

      reservedMemory = lib.mkOption {
        type = lib.types.str;
        default = "3Gi";
        description = "Memory kept out of pod scheduling for the host and its other workloads.";
      };

      adminGroup = lib.mkOption {
        type = lib.types.str;
        default = "k3s";
        description = "Group allowed to read the cluster admin kubeconfig.";
      };
    };

    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        users.groups.${cfg.adminGroup} = {};

        services.k3s = {
          enable = true;
          role = "server";
          disable = ["servicelb"];
          gracefulNodeShutdown.enable = true;
          extraFlags = [
            "--data-dir=${cfg.dataDir}"
            "--default-local-storage-path=${cfg.dataDir}/volumes"
            "--kubelet-arg=root-dir=${cfg.dataDir}/kubelet"
            # A flag, not extraKubeProxyConfig: a kube-proxy config file overrides the flags k3s sets.
            "--kube-proxy-arg=nodeport-addresses=127.0.0.1/32"
            "--tls-san=${cfg.apiAddress}"
            "--write-kubeconfig-mode=0640"
            "--write-kubeconfig-group=${cfg.adminGroup}"
          ];
          extraKubeletConfig = {
            containerLogMaxSize = "10Mi";
            containerLogMaxFiles = 3;
            systemReserved.memory = cfg.reservedMemory;
            evictionHard."memory.available" = "500Mi";
          };
          manifests.traefik-config.content = traefikConfig;
        };

        # Pod logs leave the tmpfs root for the data disk.
        fileSystems.${podLogs} = {
          device = "${cfg.dataDir}/pod-logs";
          fsType = "none";
          options = ["bind" "x-systemd.requires-mounts-for=${cfg.dataDir}"];
        };

        systemd = {
          tmpfiles.rules = [
            "d ${cfg.dataDir} 0700 root root -"
            "d ${cfg.dataDir}/pod-logs 0755 root root -"
          ];
          services.k3s = {
            requires = ["var-log-pods.mount"];
            after = ["var-log-pods.mount"];
          };
        };

        environment = {
          systemPackages = with pkgs; [kubectl kubernetes-helm k9s];
          variables.KUBECONFIG = kubeconfig;
        };

        networking.firewall = {
          trustedInterfaces = ["cni0" "flannel.1"];
          interfaces.${cfg.apiInterface}.allowedTCPPorts = [6443];
        };
      }

      # The node password must survive reboots, or the server rejects its own node.
      (lib.optionalAttrs hasPersistDirs {
        persist.system.directories = ["/etc/rancher/node"];
      })

      (lib.optionalAttrs hasUserName {
        users.users.${config.userName}.extraGroups = [cfg.adminGroup];
      })
    ]);
  };
}
