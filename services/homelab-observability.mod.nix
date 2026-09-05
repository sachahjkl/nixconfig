_: {
  flake.nixosModules.homelabObservability = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf mkOption types;
    cfg = config.homelab.services.observability;
    yaml = pkgs.formats.yaml {};
    dataRoot = "${config.homelab.dataRoot}/Docker/appdata/observability";
    network = "services";

    collectorConfig = yaml.generate "otel-collector.yaml" {
      receivers.otlp.protocols = {
        grpc.endpoint = "0.0.0.0:4317";
        http.endpoint = "0.0.0.0:4318";
      };
      processors = {
        memory_limiter = {
          check_interval = "5s";
          limit_mib = 384;
          spike_limit_mib = 96;
        };
        batch = {
          send_batch_size = 1024;
          timeout = "5s";
        };
      };
      exporters = {
        "otlp/tempo" = {
          endpoint = "tempo:4317";
          tls.insecure = true;
        };
        "otlphttp/loki".endpoint = "http://loki:3100/otlp";
        prometheus.endpoint = "0.0.0.0:8889";
      };
      extensions.health_check.endpoint = "0.0.0.0:13133";
      service = {
        extensions = ["health_check"];
        telemetry.metrics.readers = [
          {
            pull.exporter.prometheus = {
              host = "0.0.0.0";
              port = 8888;
            };
          }
        ];
        pipelines = {
          traces = {
            receivers = ["otlp"];
            processors = ["memory_limiter" "batch"];
            exporters = ["otlp/tempo"];
          };
          logs = {
            receivers = ["otlp"];
            processors = ["memory_limiter" "batch"];
            exporters = ["otlphttp/loki"];
          };
          metrics = {
            receivers = ["otlp"];
            processors = ["memory_limiter" "batch"];
            exporters = ["prometheus"];
          };
        };
      };
    };

    lokiConfig = yaml.generate "loki.yaml" {
      auth_enabled = false;
      server.http_listen_port = 3100;
      common = {
        path_prefix = "/loki";
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
        storage.filesystem = {
          chunks_directory = "/loki/chunks";
          rules_directory = "/loki/rules";
        };
      };
      schema_config.configs = [
        {
          from = "2026-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      compactor = {
        working_directory = "/loki/compactor";
        retention_enabled = true;
        delete_request_store = "filesystem";
      };
      limits_config = {
        retention_period = cfg.logsRetention;
        allow_structured_metadata = true;
        volume_enabled = true;
      };
    };

    tempoConfig = yaml.generate "tempo.yaml" {
      server.http_listen_port = 3200;
      distributor.receivers.otlp.protocols = {
        grpc.endpoint = "0.0.0.0:4317";
        http.endpoint = "0.0.0.0:4318";
      };
      live_store.max_block_duration = "5m";
      backend_scheduler.provider.compaction.compaction.block_retention = cfg.tracesRetention;
      storage.trace = {
        backend = "local";
        wal.path = "/var/tempo/wal";
        local.path = "/var/tempo/blocks";
      };
    };

    prometheusConfig = yaml.generate "prometheus.yaml" {
      global = {
        scrape_interval = "15s";
        evaluation_interval = "15s";
      };
      scrape_configs = [
        {
          job_name = "otel-collector";
          static_configs = [{targets = ["otel-collector:8888" "otel-collector:8889"];}];
        }
        {
          job_name = "loki";
          static_configs = [{targets = ["loki:3100"];}];
        }
        {
          job_name = "tempo";
          static_configs = [{targets = ["tempo:3200"];}];
        }
        {
          job_name = "grafana";
          static_configs = [{targets = ["grafana:3000"];}];
        }
        {
          job_name = "prometheus";
          static_configs = [{targets = ["prometheus:9090"];}];
        }
      ];
    };

    grafanaDatasources = yaml.generate "grafana-datasources.yaml" {
      apiVersion = 1;
      datasources = [
        {
          name = "Prometheus";
          uid = "prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://prometheus:9090";
          isDefault = true;
          editable = false;
        }
        {
          name = "Loki";
          uid = "loki";
          type = "loki";
          access = "proxy";
          url = "http://loki:3100";
          editable = false;
        }
        {
          name = "Tempo";
          uid = "tempo";
          type = "tempo";
          access = "proxy";
          url = "http://tempo:3200";
          editable = false;
          jsonData = {
            httpMethod = "GET";
            nodeGraph.enabled = true;
            serviceMap.datasourceUid = "prometheus";
            tracesToLogsV2 = {
              datasourceUid = "loki";
              filterByTraceID = true;
              filterBySpanID = true;
              spanStartTimeShift = "-1m";
              spanEndTimeShift = "1m";
            };
          };
        }
      ];
    };

    containerServices = [
      "docker-grafana"
      "docker-loki"
      "docker-otel-collector"
      "docker-prometheus"
      "docker-tempo"
    ];
  in {
    options.homelab.services.observability = {
      enable = mkEnableOption "the central observability stack";

      grafanaDomain = mkOption {
        type = types.str;
        default = "grafana.sacha.house";
        description = "Public domain for Grafana.";
      };

      otlpDomain = mkOption {
        type = types.str;
        default = "otlp.sacha.house";
        description = "Public domain for OTLP/HTTP ingestion.";
      };

      grafanaEnvironmentFile = mkOption {
        type = types.str;
        default = "/run/secrets/observability/grafana-environment";
        description = "Environment file containing the Grafana administrator password.";
      };

      otlpBasicAuthFile = mkOption {
        type = types.str;
        default = "/run/secrets/observability/otlp-htpasswd";
        description = "htpasswd file used by the OTLP reverse proxy.";
      };

      logsRetention = mkOption {
        type = types.str;
        default = "720h";
        description = "Loki log retention.";
      };

      tracesRetention = mkOption {
        type = types.str;
        default = "336h";
        description = "Tempo trace retention.";
      };

      metricsRetention = mkOption {
        type = types.str;
        default = "30d";
        description = "Prometheus metric retention.";
      };
    };

    config = mkIf cfg.enable {
      virtualisation.oci-containers = {
        backend = "docker";
        containers = {
          loki = {
            image = "grafana/loki:3.7.7";
            cmd = ["-config.file=/etc/loki/config.yaml"];
            volumes = [
              "${lokiConfig}:/etc/loki/config.yaml:ro"
              "${dataRoot}/loki:/loki"
            ];
            networks = [network];
          };

          tempo = {
            image = "grafana/tempo:3.0.3";
            cmd = ["-config.file=/etc/tempo/config.yaml"];
            volumes = [
              "${tempoConfig}:/etc/tempo/config.yaml:ro"
              "${dataRoot}/tempo:/var/tempo"
            ];
            networks = [network];
          };

          otel-collector = {
            image = "otel/opentelemetry-collector-contrib:0.160.0";
            cmd = ["--config=/etc/otelcol/config.yaml"];
            volumes = ["${collectorConfig}:/etc/otelcol/config.yaml:ro"];
            networks = [network];
            dependsOn = ["loki" "tempo"];
          };

          prometheus = {
            image = "prom/prometheus:v3.14.0";
            cmd = [
              "--config.file=/etc/prometheus/prometheus.yaml"
              "--storage.tsdb.path=/prometheus"
              "--storage.tsdb.retention.time=${cfg.metricsRetention}"
              "--storage.tsdb.retention.size=20GB"
            ];
            volumes = [
              "${prometheusConfig}:/etc/prometheus/prometheus.yaml:ro"
              "${dataRoot}/prometheus:/prometheus"
            ];
            networks = [network];
            dependsOn = ["otel-collector"];
          };

          grafana = {
            image = "grafana/grafana:13.2.1";
            environment = {
              GF_SERVER_DOMAIN = cfg.grafanaDomain;
              GF_SERVER_ROOT_URL = "https://${cfg.grafanaDomain}";
              GF_SECURITY_ADMIN_USER = "admin";
              GF_USERS_ALLOW_SIGN_UP = "false";
              GF_AUTH_ANONYMOUS_ENABLED = "false";
            };
            environmentFiles = [cfg.grafanaEnvironmentFile];
            volumes = [
              "${grafanaDatasources}:/etc/grafana/provisioning/datasources/observability.yaml:ro"
              "${dataRoot}/grafana:/var/lib/grafana"
            ];
            networks = [network];
            dependsOn = ["loki" "prometheus" "tempo"];
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d ${dataRoot} 0750 root root -"
        "d ${dataRoot}/grafana 0750 472 472 -"
        "d ${dataRoot}/loki 0750 10001 10001 -"
        "d ${dataRoot}/prometheus 0750 65534 65534 -"
        "d ${dataRoot}/tempo 0750 10001 10001 -"
      ];

      systemd.services = lib.genAttrs containerServices (_: {
        after = ["docker-create-services-network.service"];
        requires = ["docker-create-services-network.service"];
      });
    };
  };
}
