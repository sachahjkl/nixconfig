_: {
  flake.nixosModules.homelabProxyHosts = {config, ...}: let
    observability = config.homelab.services.observability;
  in {
    services.nginx.defaultListenAddresses = ["127.0.0.1"];

    homelab.proxy = {
      enable = true;
      address = "192.168.50.22";
      acmeEmail = "sacha@sacha.house";
      defaultDomainRedirect = "sacha.house";
      dns = {
        acmeZoneNames = ["sacha.house"];
        defaultType = "CNAME";
        defaultValue = "82.66.185.90";
        defaultProxied = false;
        defaultTarget = "homelab.sacha.house";
        cnames = {
          "*.homelab.sacha.house" = "homelab.sacha.house";
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
          websockets = true;
        };

        ${observability.otlpDomain} = {
          dockerContainer = "otel-collector";
          dockerPort = 4318;
          basicAuthFile = observability.otlpBasicAuthFile;
          extraConfig = "client_max_body_size 16m;";
        };

        "secret.homelab.sacha.house" = {
          dockerContainer = "vaultwarden";
          dockerPort = 80;
          websockets = true;
        };

        "cache.homelab.sacha.house" = {
          upstreamHost = "127.0.0.1";
          upstreamPort = 5000;
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
          websockets = true;
        };

        "debrid.homelab.sacha.house" = {
          dockerContainer = "rdtclient";
          dockerPort = 6500;
        };

        "homelab.sacha.house" = {
          dockerContainer = "Dashy";
          dockerPort = 8080;
          websockets = true;
          dns = {
            type = "A";
            value = "82.66.185.90";
            proxied = false;
          };
        };

        "pixels.aubetoile.dev" = {
          dockerContainer = "pixelsaubetoiledev-pixels_web-1";
          dockerPort = 80;
          websockets = true;
          dns.enable = false;
        };

        "api.pixels.aubetoile.dev" = {
          dockerContainer = "pixelsaubetoiledev-pixels_api-1";
          dockerPort = 8080;
          websockets = true;
          dns.enable = false;
        };

        "ai.sacha.house" = {
          upstreamHost = "127.0.0.1";
          upstreamPort = 4096;
          websockets = true;
        };

        "router.sacha.house" = {
          scheme = "https";
          upstreamHost = "192.168.50.1";
          upstreamPort = 8443;
          websockets = true;
        };

        "froment.software" = {
          upstreamHost = "127.0.0.1";
          upstreamPort = 9012;
          dns = {
            type = "A";
            value = "82.66.185.90";
            proxied = false;
          };
        };

        "staging.froment.software" = {
          upstreamHost = "127.0.0.1";
          upstreamPort = 9011;
          robotsNoIndex = true;
        };

        "portainer.homelab.sacha.house" = {
          dockerContainer = "portainer";
          dockerPort = 9000;
          websockets = true;
        };

        "files.sacha.house" = {
          upstreamHost = "127.0.0.1";
          upstreamPort = 8082;
          websockets = true;
        };
      };
    };
  };
}
