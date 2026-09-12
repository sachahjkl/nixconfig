# Homelab application template

This repository deploys one application to staging and production on the homelab platform.

## Configure the application

Edit `application.yaml` before the first deployment:

```yaml
application:
  name: example
  port: 8080
  healthPath: /health

domain:
  production: example.sacha.house
  staging: staging.example.sacha.house
```

Choose each domain explicitly. The platform accepts subdomains of:

- `sacha.house`;
- `homelab.sacha.house`;
- `froment.software`.

The wildcard DNS records route these domains to Traefik automatically.

Add this optional block when the application stores persistent data:

```yaml
volume:
  mountPath: /data
```

The deployment creates one Nomad dynamic host volume per environment.

Removing this block does not delete existing data.

## Replace the example application

Replace the Caddy example with your application package and OCI image.

Keep these flake interfaces:

- `nix flake check` validates the application;
- `nix build .#dockerImage` creates the OCI archive;
- `nix run .#deploymentConfig` validates deployment configuration.

The container must listen on `application.port`. The health endpoint must match `application.healthPath`.

## Deploy

Push an accepted commit to `master`. CI checks, publishes, signs, and deploys the image to staging.

Run the `Deploy production` workflow. Approve the protected production environment.

Production receives the exact OCI digest that runs in staging.
