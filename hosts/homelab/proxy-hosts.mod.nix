_: {
  flake.nixosModules.homelabProxyHosts = {config, ...}: let
    observability = config.homelab.services.observability;
  in {
    homelab.proxy = {
      enable = true;
      address = "192.168.50.22";
      acmeEmail = "sacha@sacha.house";
      defaultDomainRedirect = "sacha.house";
      dns = {
        aRecords."froment.software" = "82.66.185.90";
        acmeZoneNames = [
          "froment.software"
          "sacha.house"
        ];
        defaultType = "CNAME";
        defaultValue = "82.66.185.90";
        defaultProxied = false;
        defaultTarget = "homelab.sacha.house";
        cnames = {
          "*.homelab.sacha.house" = "homelab.sacha.house";
          "*.froment.software" = "froment.software";
          "*.sacha.house" = "homelab.sacha.house";
          "sacha.house" = "homelab.sacha.house";
          "www.froment.software" = "froment.software";
          "www.sacha.house" = "sacha.house";
        };
        zoneNames = [
          "sacha.house"
          "froment.software"
        ];
      };
      hosts = {
        ${observability.grafanaDomain} = {
          dockerContainer = "grafana";
          dockerPort = 3000;
        };

        ${observability.otlpDomain} = {
          dockerContainer = "otel-collector";
          dockerPort = 4318;
          basicAuthFile = observability.otlpBasicAuthFile;
          maxRequestBodyBytes = 16777216;
        };

        "secret.homelab.sacha.house" = {
          dockerContainer = "vaultwarden";
          dockerPort = 80;
        };

        "cache.homelab.sacha.house" = {
          upstreamHost = "127.0.0.1";
          upstreamPort = 5000;
          pathRoutes = [
            {
              rule = "Path(`/`) || Path(`/status.json`)";
              upstreamHost = "127.0.0.1";
              upstreamPort = 5001;
            }
          ];
        };

        "aubetoile.dev" = {
          dockerContainer = "aubetoile";
          dockerPort = 80;
          dns = {
            enable = false;
          };
        };

        "sae.aubetoile.dev" = {
          dockerContainer = "sae.aubetoile";
          dockerPort = 8080;
          dns.enable = false;
        };

        "dns.sacha.house" = {
          dockerContainer = "pihole";
          dockerPort = 80;
        };

        "debrid.homelab.sacha.house" = {
          dockerContainer = "rdtclient";
          dockerPort = 6500;
        };

        "homelab.sacha.house" = {
          dockerContainer = "Dashy";
          dockerPort = 8080;
          dns = {
            type = "A";
            value = "82.66.185.90";
            proxied = false;
          };
        };

        "pixels.aubetoile.dev" = {
          dockerContainer = "pixelsaubetoiledev-pixels_web-1";
          dockerPort = 80;
          dns.enable = false;
        };

        "api.pixels.aubetoile.dev" = {
          dockerContainer = "pixelsaubetoiledev-pixels_api-1";
          dockerPort = 8080;
          dns.enable = false;
        };

        "ai.sacha.house" = {
          upstreamHost = "127.0.0.1";
          upstreamPort = 4096;
        };

        "router.sacha.house" = {
          scheme = "https";
          upstreamHost = "192.168.50.1";
          upstreamPort = 8443;
        };

        "portainer.homelab.sacha.house" = {
          dockerContainer = "portainer";
          dockerPort = 9000;
        };

        "files.sacha.house" = {
          upstreamHost = "127.0.0.1";
          upstreamPort = 8082;
        };
      };
    };
  };
}
