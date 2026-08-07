_: {
  flake.serviceModules.base = {
    config,
    lib,
    name,
    options,
    ...
  }: let
    inherit (lib) mkIf mkMerge mkOption types;
    rootful = builtins.elem "CAP_DAC_OVERRIDE" config.limits.capabilities;

    familyType = types.nullOr (types.submodule {
      options = {
        tcp = mkOption {
          type = types.nullOr (types.either types.port types.str);
          default = null;
        };
        udp = mkOption {
          type = types.nullOr (types.either types.port types.str);
          default = null;
        };
      };
    });

    portsOf = bind:
      builtins.filter (port: port != null) (
        lib.optionals (bind.v4 != null) [bind.v4.tcp bind.v4.udp]
        ++ lib.optionals (bind.v6 != null) [bind.v6.tcp bind.v6.udp]
      );

    bindAllow = family: protocol: port:
      lib.optional (port != null && port != 0) "${family}:${protocol}:${toString port}";
    credentialEnvironment = lib.mapAttrs' (credentialName: credential:
      lib.nameValuePair credential.environment "%d/${credentialName}")
    (lib.filterAttrs (_: credential: credential.environment != null) config.exec.credentials);
  in {
    options = {
      exec = {
        allow = mkOption {
          type = types.listOf (types.either types.package types.str);
          default = [];
          description = "Additional executable paths exposed to the service.";
        };

        allowMemory = mkOption {
          type = types.bool;
          default = false;
          description = "Allow writable executable memory for JIT runtimes.";
        };

        again = mkOption {
          type = types.enum ["no" "on-success" "on-failure" "on-abnormal" "on-watchdog" "on-abort" "always"];
          default = "on-failure";
          description = "When the service should restart.";
        };

        after = mkOption {
          type = types.str;
          default = "10s";
          description = "Delay before restarting the service.";
        };

        argv = mkOption {
          type = types.listOf (types.either types.path types.str);
          description = "Portable service argument vector.";
        };

        credentials = mkOption {
          type = types.attrsOf (types.submodule {
            options = {
              source = mkOption {
                type = types.either types.path types.str;
                description = "Protected credential source for the init adapter.";
              };

              environment = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Environment variable that receives the adapter credential path.";
              };
            };
          });
          default = {};
          description = "Named protected credentials provided to the service.";
        };

        environment = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = "Environment variables provided to the service.";
        };

        path = mkOption {
          type = types.listOf types.package;
          default = [];
          description = "Packages whose executables are available to the service.";
        };

        workingDirectory = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Working directory for the service process.";
        };
      };

      network = {
        reach = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "IP address ranges the service may exchange traffic with.";
        };

        bind = mkOption {
          type = types.listOf (types.submodule {
            options = {
              v4 = mkOption {
                type = familyType;
                default = null;
              };
              v6 = mkOption {
                type = familyType;
                default = null;
              };
              unix = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
            };
          });
          default = [];
          description = "Sockets the service may bind.";
        };
      };

      files = mkOption {
        type = types.attrsOf (types.listOf (types.enum ["read" "write"]));
        default = {};
        description = "Filesystem paths exposed to the service.";
      };

      limits = {
        fd = mkOption {
          type = types.nullOr types.ints.unsigned;
          default = null;
        };

        capabilities = mkOption {
          type = types.listOf types.str;
          default = [];
        };

        storage = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to provide a persistent state directory.";
        };

        syscalls = mkOption {
          type = types.listOf types.str;
          default = ["@system-service"];
          description = "Allowed system calls or systemd syscall groups.";
        };

        architectures = mkOption {
          type = types.listOf types.str;
          default = ["native"];
        };
      };
    };

    config = {
      process.argv = config.exec.argv;

      ${
        if options ? systemd
        then "systemd"
        else null
      }.service = {
        path = config.exec.path;
        environment = config.exec.environment // credentialEnvironment;
        serviceConfig = mkMerge [
          {
            NoExecPaths = "/";
            ExecPaths = ["/nix/store"] ++ config.exec.allow;
            MemoryDenyWriteExecute = !config.exec.allowMemory;
            NoNewPrivileges = true;
            Restart = config.exec.again;
            RestartSec = config.exec.after;
          }

          {
            PrivateNetwork = config.network.reach == [];
            IPAddressDeny = "any";
            IPAddressAllow = config.network.reach;

            SocketBindDeny = mkIf (!(builtins.any (port: port == 0) (lib.concatMap portsOf config.network.bind))) "any";
            SocketBindAllow = lib.concatMap (bind:
              lib.optionals (bind.v4 != null) (bindAllow "ipv4" "tcp" bind.v4.tcp ++ bindAllow "ipv4" "udp" bind.v4.udp)
              ++ lib.optionals (bind.v6 != null) (bindAllow "ipv6" "tcp" bind.v6.tcp ++ bindAllow "ipv6" "udp" bind.v6.udp))
            config.network.bind;

            RestrictAddressFamilies =
              ["AF_UNIX"]
              ++ lib.optional (builtins.any (bind: bind.v4 != null) config.network.bind || builtins.any lib.network.isAddressV4 config.network.reach) "AF_INET"
              ++ lib.optional (builtins.any (bind: bind.v6 != null) config.network.bind || builtins.any lib.network.isAddressV6 config.network.reach) "AF_INET6";
          }

          (let
            pathsWith = predicate: lib.attrNames (lib.filterAttrs (lib.const predicate) config.files);
          in {
            InaccessiblePaths = pathsWith (capabilities: capabilities == []);
            ReadOnlyPaths = pathsWith (capabilities: builtins.elem "read" capabilities && !(builtins.elem "write" capabilities));
            ReadWritePaths = pathsWith (builtins.elem "write");
            PrivateMounts = true;
            PrivateTmp = "disconnected";
            ProtectHome = true;
            ProtectSystem = "strict";
          })

          (mkIf config.limits.storage {
            StateDirectory = name;
            StateDirectoryMode = "0700";
            WorkingDirectory = "%S/${name}";
          })

          {
            DevicePolicy = "closed";
            PrivateDevices = true;
            LockPersonality = true;
            ProtectClock = true;
            ProtectControlGroups = "strict";
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            RestrictRealtime = true;
            PrivateIPC = true;
            ProcSubset = "pid";
            ProtectProc = "invisible";
            RemoveIPC = true;
            PrivatePIDs = true;
            PrivateBPF = false;
            AmbientCapabilities = lib.concatStringsSep " " config.limits.capabilities;
            CapabilityBoundingSet = lib.concatStringsSep " " config.limits.capabilities;
            DynamicUser = !rootful;
            RestrictSUIDSGID = true;
            UMask = "0077";
            PrivateUsers = !rootful;
            RestrictNamespaces = true;
            LimitCORE = 0;
            LimitNOFILE = mkIf (config.limits.fd != null) config.limits.fd;
            SystemCallArchitectures = config.limits.architectures;
            SystemCallFilter = config.limits.syscalls;
          }

          (mkIf (config.exec.workingDirectory != null) {
            WorkingDirectory = config.exec.workingDirectory;
          })

          {
            LoadCredential =
              lib.mapAttrsToList (credentialName: credential: "${credentialName}:${toString credential.source}")
              config.exec.credentials;
          }
        ];
      };
    };
  };
}
