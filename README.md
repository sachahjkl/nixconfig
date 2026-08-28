[English](README.md) | [Français](README.fr.md)

# nixconfig

Sacha's NixOS flake.

## Layout

```text
.
├── flake.nix
├── hosts/        # host entrypoints, hardware modules, disko configs
├── modules/      # reusable NixOS modules and aggregate modules
├── options/      # flake-parts output/options helpers
├── packages/     # wrapped packages, dev shells, formatter, custom packages
├── services/     # homelab service modules
├── lib/          # local flake library helpers
└── secrets.nix   # agenix recipient rules
```

`flake.nix` imports every `*.mod.nix` file as a `flake-parts` module. Normal NixOS module files must therefore be exported through `flake.nixosModules.<name>`.

## Hosts

Current host outputs:

```bash
nix flake show 'path:/home/sacha/Projects/nixconfig'
```

Main hosts:

```text
house-desktop
house-laptop
homelab
wsl
```

Host files are intentionally thin. They import aggregate modules such as `workstation`, `desktop`, `hyprland`, `niri`, `gaming`, or `homelab`, then set host-specific hardware and preferences.

## Fresh Setup

Clone the repo where the config expects it:

```bash
mkdir -p /home/sacha/Projects
git clone git@github.com:sachahjkl/nixconfig.git /home/sacha/Projects/nixconfig
cd /home/sacha/Projects/nixconfig
```

If the host uses agenix secrets, restore the dedicated agenix private key from Bitwarden:

```bash
install -m 700 -d ~/.ssh
$EDITOR ~/.ssh/agenix
chmod 600 ~/.ssh/agenix
```

The public key is declared in `modules/keys.mod.nix`. Do not use the YubiKey resident `sk-*` SSH key for agenix; agenix needs a normal decryptable SSH key.

If the host uses `sops-nix` secrets, keep the same age private key in two places:

1. User copy for editing encrypted files with `sops` interactively.
2. Root-owned host copy for activation-time decryption through `sops-nix`.

Put the user copy here:

```bash
mkdir -p ~/.config/sops/age
install -m 600 /path/to/shared-age-key.txt ~/.config/sops/age/keys.txt
```

`sops` looks in `~/.config/sops/age/keys.txt` by default. This repo pre-creates `~/.config/sops/age` for the primary user and preserves `.config/sops`, so the key survives normal rebuilds and restarts on preserved hosts.

Put the root-owned host copy here:

```bash
sudo mkdir -p /var/lib/sops-nix
sudo install -m 0400 -o root -g root /path/to/shared-age-key.txt /var/lib/sops-nix/key.txt
```

`sops-nix` uses `/var/lib/sops-nix/key.txt` during activation to decrypt runtime secret files such as password hashes, Tailscale auth keys, and service credentials. `/var/lib/sops-nix` is included in the shared preservation set, so the key survives normal reboots and rebuilds on preserved hosts.

This repo also provides a helper app that installs both copies for you:

```bash
nix run .#bootstrapAge
```

By default it expects the secret USB label `<hostname>.s`, mounts it at `/media/key` if needed, looks for one of `key.txt`, `shared-age-key.txt`, `sops-age-key.txt`, or `.secrets.key`, then installs the key to both:

```text
~/.config/sops/age/keys.txt
/var/lib/sops-nix/key.txt
```

It also supports explicit sources:

```bash
nix run .#bootstrapAge -- --from-file /path/to/shared-age-key.txt
nix run .#bootstrapAge -- --from-value 'AGE-SECRET-KEY-...'
```

Other useful flags:

```bash
nix run .#bootstrapAge -- --label homelab.s
nix run .#bootstrapAge -- --to-mounted-system
nix run .#bootstrapAge -- --to-mounted-system=/mnt/some-other-root
nix run .#bootstrapAge -- --help
```

`--to-mounted-system` is useful from the NixOS live ISO after `disko` has mounted the target root. It also installs the activation-time copy into `<target>/var/lib/sops-nix/key.txt`, so you can run `nixos-install` without manually copying the key into `/mnt` first.

Shared and host-specific encrypted secret payloads now live in:

```text
secrets/shared.yaml
secrets/homelab.yaml
```

Edit them with:

```bash
nix shell nixpkgs#sops -c sops secrets/shared.yaml
nix shell nixpkgs#sops -c sops secrets/homelab.yaml
```

Normal workflow:

1. Open the relevant encrypted file with `sops`.
2. Edit the plaintext values in your editor.
3. Save and exit. `sops` re-encrypts the file in place.
4. Rebuild the host so `sops-nix` refreshes the runtime secret files.

Current split:

- `secrets/shared.yaml`: shared cross-host secrets such as `shared.password-hash` and `tailscale.user-authkey`.
- `secrets/homelab.yaml`: homelab-only secrets such as `tailscale.server-authkey`, `restic.password`, and `restic.environment`.

To inspect the decrypted contents without editing:

```bash
nix shell nixpkgs#sops -c sops decrypt secrets/shared.yaml
nix shell nixpkgs#sops -c sops decrypt secrets/homelab.yaml
```

After changing secrets, apply them with your usual rebuild flow, for example:

```bash
nh os switch --hostname house-desktop
nh os switch --hostname house-laptop
sudo nixos-rebuild switch --flake /home/sacha/Projects/nixconfig#homelab
```

## GitHub Actions Runner

The homelab module provides disabled GitHub Actions runners under `homelab.services.githubRunner`.

GitHub does not support account-wide runners for personal accounts. The module registers one runner instance for each configured repository.

Create a dedicated fine-grained PAT with runner access to all configured repositories. Add it as `github.actions-runner` in `secrets/homelab.yaml`:

```bash
nix shell nixpkgs#sops -c sops secrets/homelab.yaml
```

Enable the runners on `homelab` after the repository URLs and encrypted PAT exist:

```nix
homelab.services.githubRunner = {
  enable = true;
  repositories = {
    git-migrate = "https://github.com/owner/git-migrate";
    nixconfig = "https://github.com/owner/nixconfig";
  };
};
```

Each service runs as the `github-runner` system user. It uses journald and provides the default `self-hosted`, `linux`, and `x64` labels.

The module also adds `nixos`, `nix`, and `homelab`. Workflows can select it with `runs-on: [self-hosted, nixos]`.

After deployment, verify the service and Nix access:

```bash
systemctl status github-runner-git-migrate
journalctl -u github-runner-git-migrate
sudo -u github-runner nix --version
```

Use a manual workflow in the registered repository to test job assignment:

```yaml
name: Homelab runner test
on:
  workflow_dispatch:
jobs:
  check:
    runs-on: [self-hosted, nixos]
    steps:
      - uses: actions/checkout@v4
      - run: nix --version
      - run: nix flake check
```

## Observability

The `homelabObservability` module deploys the following services in Docker:

- OpenTelemetry Collector receives OTLP traces, logs, and metrics.
- Loki retains logs for 30 days.
- Tempo retains traces for 14 days.
- Prometheus retains metrics for 30 days, with a 20 GB limit.
- Grafana provides preconfigured Prometheus, Loki, and Tempo data sources.

The data resides in `/data/Docker/appdata/observability`.

The Restic service already backs up this directory through its parent, `/data/Docker/appdata`.

Configure the domains in `hosts/homelab/homelab.mod.nix`:

```nix
homelab.services.observability = {
  enable = true;
  grafanaDomain = "grafana.sacha.house";
  otlpDomain = "otlp.sacha.house";
};
```

Use `admin` as the Grafana username.

Decrypt the Grafana password with this command:

```bash
sops decrypt --extract '["observability"]["grafana-environment"]' secrets/homelab.yaml
```

Configure Froment with these variables:

```text
OTEL_TRACES_EXPORTER=otlp
OTEL_LOGS_EXPORTER=otlp
OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp.sacha.house
OTEL_EXPORTER_OTLP_HEADERS=Authorization=Basic%20<identifiants-base64>
DEPLOYMENT_ENVIRONMENT=production
```

Generate the Base64 credentials without writing the password to disk:

```bash
OTLP_PASSWORD="$(sops decrypt --extract '["observability"]["otlp-password"]' secrets/homelab.yaml)"
printf 'froment:%s' "$OTLP_PASSWORD" | base64 -w0
unset OTLP_PASSWORD
```

The proxy accepts OTLP/HTTP with protobuf on `/v1/traces`, `/v1/logs`, and `/v1/metrics`.

Apply the configuration with the usual rebuild procedure.

## Rebuild

Preferred:

```bash
nh os switch --hostname house-desktop
nh os switch --hostname house-laptop
```

Directly:

```bash
sudo nixos-rebuild switch --flake /home/sacha/Projects/nixconfig#house-desktop
sudo nixos-rebuild switch --flake /home/sacha/Projects/nixconfig#house-laptop
```

## Fresh Install

Boot a NixOS ISO, clone the repo, then run the host's disko config.

Warning: disko is destructive. Verify the target disk in the host's `hosts/<host>/disko.mod.nix` before running it.

### TL;DR: install `homelab` from the NixOS ISO

```bash
mkdir -p /home/nixos/Projects
git clone git@github.com:sachahjkl/nixconfig.git /home/nixos/Projects/nixconfig
cd /home/nixos/Projects/nixconfig
sudo nix --extra-experimental-features 'nix-command flakes' \
  run github:nix-community/disko -- \
  --mode destroy,format,mount \
  --flake 'path:/home/nixos/Projects/nixconfig#homelab'
nix run .#bootstrapAge -- --to-mounted-system
sudo nixos-install --root /mnt --flake 'path:/home/nixos/Projects/nixconfig#homelab'
reboot
cd /data/Home/sacha/Projects/nixconfig
nix run .#bootstrapAge
sudo nixos-rebuild switch --flake /data/Home/sacha/Projects/nixconfig#homelab
```

The first `bootstrapAge` call from the ISO seeds the activation key into `/mnt/var/lib/sops-nix/key.txt` so `nixos-install` can decrypt secrets. The second call after reboot installs the key for normal user editing as well.

For encrypted/FIDO2 systems, keep at least one recovery passphrase and verify YubiKey unlock before relying on the install.

## Secure Boot

This config uses Limine with Secure Boot support. Initial setup usually needs keys generated and enrolled manually.

Generate keys:

```bash
nix shell nixpkgs#sbctl
sudo sbctl create-keys
```

After first successful boot, enroll keys while preserving Microsoft certificates:

```bash
sudo sbctl enroll-keys --microsoft
```

Verify and sign Limine EFI binaries if needed:

```bash
sudo sbctl status
sudo sbctl verify
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
```

## Verification

Use `path:` so untracked files are included during development:

```bash
nix flake check 'path:/home/sacha/Projects/nixconfig' --no-write-lock-file
```

Build a host without switching:

```bash
nix build 'path:/home/sacha/Projects/nixconfig#nixosConfigurations.house-desktop.config.system.build.toplevel' --dry-run
```

## Updating Opencode

`opencode` is pinned through the `opencode-src` flake input.

To update it, edit `flake.nix` to the desired tag, for example:

```nix
opencode-src.url = "github:anomalyco/opencode/v1.17.3";
```

Then update the lock and build once:

```bash
nix flake update opencode-src
nix build 'path:/home/sacha/Projects/nixconfig#opencode' --no-link
```

If Nix reports a `node_modules` hash mismatch, copy the reported `got:` hash into `packages/opencode/opencode.mod.nix`.
