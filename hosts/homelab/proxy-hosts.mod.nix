_: {
  flake.nixosModules.homelabProxyHosts = {
    homelab.proxy = {
      enable = true;
      acmeEmail = "sacha@sacha.house";
      defaultDomainRedirect = "sacha.house";
      hosts = {
        "secret.homelab.sacha.house" = {
          dockerContainer = "vaultwarden";
          dockerPort = 80;
          websockets = true;
        };

        "htmx.sacha.house" = {
          dockerContainer = "htmxgo";
          dockerPort = 7883;
          websockets = true;
        };

        "sacha.house" = {
          upstreamHost = "127.0.0.1";
          upstreamPort = 6969;
        };

        "musee.sacha.house" = {
          dockerContainer = "musee-app";
          dockerPort = 80;
          websockets = true;
        };

        "button.sacha.house" = {
          dockerContainer = "button-sacha-house";
          dockerPort = 3000;
        };

        "react-training.sacha.house" = {
          dockerContainer = "react-sacha-house";
          dockerPort = 3000;
        };

        "marketing.sacha.house" = {
          dockerContainer = "marketing-sacha-house";
          dockerPort = 3000;
        };

        "albumator.sacha.house" = {
          dockerContainer = "albumator";
          dockerPort = 3000;
        };

        "nginx.sacha.house" = {
          upstreamHost = "127.0.0.1";
          upstreamPort = 81;
          websockets = true;
        };

        "aubetoile.dev" = {
          dockerContainer = "valentin-froment-site";
          dockerPort = 80;
        };

        "sae.aubetoile.dev" = {
          dockerContainer = "sae.aubetoile";
          dockerPort = 8080;
        };

        "admin.sacha.house" = {
          upstreamHost = "127.0.0.1";
          upstreamPort = 8000;
          websockets = true;
        };

        "dns.sacha.house" = {
          dockerContainer = "pihole";
          dockerPort = 80;
          websockets = true;
        };

        "wthhyb.sacha.house" = {
          dockerContainer = "wthhyb";
          dockerPort = 80;
        };

        "chat.sacha.house" = {
          dockerContainer = "chat-sacha-house";
          dockerPort = 3030;
        };

        "debrid.homelab.sacha.house" = {
          dockerContainer = "rdtclient";
          dockerPort = 6500;
        };

        "homelab.sacha.house" = {
          dockerContainer = "dashy";
          dockerPort = 8080;
          websockets = true;
        };

        "php.homelab.sacha.house" = {
          dockerContainer = "acheteteper";
          dockerPort = 8000;
        };

        "pixels.aubetoile.dev" = {
          dockerContainer = "pixels-web";
          dockerPort = 80;
          websockets = true;
        };

        "api.pixels.aubetoile.dev" = {
          dockerContainer = "pixels-api";
          dockerPort = 8080;
          websockets = true;
        };

        "ai.sacha.house" = {
          dockerContainer = "opencode";
          dockerPort = 4096;
          websockets = true;
        };

        "wetty.sacha.house" = {
          upstreamHost = "127.0.0.1";
          upstreamPort = 44888;
          websockets = true;
        };

        "router.sacha.house" = {
          scheme = "https";
          upstreamHost = "192.168.50.1";
          upstreamPort = 8443;
          websockets = true;
        };

        "froment.software" = {
          dockerContainer = "froment-software";
          dockerPort = 80;
        };

        "tmp.aubetoile.dev" = {
          dockerContainer = "valentin-froment-site";
          dockerPort = 80;
          websockets = true;
        };

        "portainer.homelab.sacha.house" = {
          dockerContainer = "portainer";
          dockerPort = 9000;
          websockets = true;
        };

        "scratch.sacha.house" = {
          dockerContainer = "ai-web-php";
          dockerPort = 80;
          websockets = true;
        };

        "hermes.sacha.house" = {
          upstreamHost = "127.0.0.1";
          upstreamPort = 9119;
          websockets = true;
          # TODO: re-add basic auth once the file is moved to a path without spaces
          # basicAuthFile = "/data/Docker/appdata/Nginx Proxy Manager/data/access/1";
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
