# nixconfig

Sacha's NixOS flake.

## Layout

```text
.
├── flake.nix
├── nix-config.nix  # shared Nix daemon/client settings
├── .sops.yaml      # SOPS age creation rules
├── hosts/          # host entrypoints, hardware modules, disko configs
├── modules/        # reusable NixOS modules and aggregate modules
├── options/        # flake-parts output/options helpers
├── packages/       # wrapped packages, dev shells, formatter, custom packages
├── secrets/        # SOPS-encrypted YAML secret files
├── services/       # homelab and WSL service modules
└── lib/            # local flake library helpers
```

`flake.nix` imports every `*.mod.nix` file as a `flake-parts` module. Normal NixOS module files must therefore be exported through `flake.nixosModules.<name>`.

## Hosts

List current host outputs:

```bash
nix flake show 'path:/home/sacha/Projects/nixconfig'
```

Hosts:

```text
house-desktop
house-laptop
kids-desktop
homelab
ogf-wsl
sacha-pc-wsl
```

Host files are thin. They compose aggregate modules such as `common`, `workstation`, `desktop`, `hyprland`, `shojiwm`, `gaming`, `kidsDesktop`, or `server`, then set host-specific hardware and preferences.

## Fresh Setup

Clone the repo where the config expects it:

```bash
mkdir -p /home/sacha/Projects
git clone git@github.com:sachahjkl/nixconfig.git /home/sacha/Projects/nixconfig
cd /home/sacha/Projects/nixconfig
```

Keep the shared SOPS age private key in two places:

1. User copy for editing encrypted files with `sops` interactively (`~/.config/sops/age/keys.txt`).
2. Root-owned host copy for activation-time decryption through `sops-nix` (`/persist/var/lib/sops-nix/key.txt` on preserved hosts; `/var/lib/sops-nix/key.txt` on non-preserved hosts such as WSL and `kids-desktop`).

Install both copies with the helper app:

```bash
nix run .#bootstrapAge
```

By default it expects the secret USB label `<hostname>.s`, mounts it at `/media/key` if needed, looks for `key.txt`, `shared-age-key.txt`, `sops-age-key.txt`, or `.secrets.key`, then installs the key to:

```text
~/.config/sops/age/keys.txt
/var/lib/sops-nix/key.txt
/persist/var/lib/sops-nix/key.txt   (when /persist exists)
```

Explicit sources and install flags:

```bash
nix run .#bootstrapAge -- --from-file /path/to/shared-age-key.txt
nix run .#bootstrapAge -- --from-value 'AGE-SECRET-KEY-...'
nix run .#bootstrapAge -- --label homelab.s
nix run .#bootstrapAge -- --to-mounted-system
nix run .#bootstrapAge -- --to-mounted-system=/mnt/some-other-root
nix run .#bootstrapAge -- --help
```

`--to-mounted-system` is useful from the NixOS live ISO after `disko` mounts the target root. It installs the activation-time copy into `<target>/var/lib/sops-nix/key.txt` and `<target>/persist/var/lib/sops-nix/key.txt` so `nixos-install` can decrypt secrets on first boot.

Encrypted secret payloads live in:

```text
secrets/shared.yaml
secrets/homelab.yaml
```

Edit or inspect them with:

```bash
nix shell nixpkgs#sops -c sops secrets/shared.yaml
nix shell nixpkgs#sops -c sops secrets/homelab.yaml
nix shell nixpkgs#sops -c sops decrypt secrets/shared.yaml
nix shell nixpkgs#sops -c sops decrypt secrets/homelab.yaml
```

Current split:

- `secrets/shared.yaml`: cross-host secrets (`shared.password-hash`, `tailscale.user-authkey`, `cloudflare.dns`, SSH/GitHub/npm/AI tokens).
- `secrets/homelab.yaml`: homelab-only secrets (`tailscale.server-authkey`, `restic.*`, `github.actions-runner`, `observability.*`, `nix-cache.*`, `nomad.*`, `web-terminal.*`, `filebrowser.*`, `opencode.*`, `opencode-telegram.*`, `registry.*`).

## GitHub Actions Runner

The `githubRunner` module provides self-hosted runners under `services.managedGithubRunners`.

Reserve this runner for the `nixconfig` repository. It checks NixOS infrastructure and populates the homelab Nix cache. Run application CI and artifact publication on GitHub-hosted runners.

Add a dedicated fine-grained PAT with runner access as `github.actions-runner` in `secrets/homelab.yaml`, then configure the runner in `hosts/homelab/homelab.mod.nix`:

```nix
services.managedGithubRunners = {
  enable = true;
  sopsFile = self + /secrets/homelab.yaml;
  repositories.nixconfig = "https://github.com/sachahjkl/nixconfig";
  trustedRepositories = ["nixconfig"];
  labels = ["nixos" "nix" "homelab"];
};
```

Trusted repositories run under `github-runner-nixconfig` (in `nix.settings.trusted-users`); other repositories run under `github-runner`. Default module labels are `["nixos" "nix"]`; `homelab` adds `"homelab"`.

Verify after deployment:

```bash
systemctl status github-runner-nixconfig
journalctl -u github-runner-nixconfig
sudo -u github-runner-nixconfig nix --version
```

## Observability

The `observabilityStack` module (`services.observabilityStack`) deploys the following services in Docker:

- OpenTelemetry Collector receives OTLP traces, logs, and metrics.
- Loki retains logs for 30 days.
- Tempo retains traces for 14 days.
- Prometheus retains metrics for 30 days, with a 20 GB limit.
- Grafana provides preconfigured Prometheus, Loki, and Tempo data sources.

Data resides in `/data/Docker/appdata/observability`, backed up via `/data/Docker/appdata`.

Configure it in `hosts/homelab/homelab.mod.nix`:

```nix
services.observabilityStack = {
  enable = true;
  dataDir = "/data/Docker/appdata/observability";
  grafanaDomain = "grafana.sacha.house";
  otlpDomain = "otlp.sacha.house";
};
```

Use `admin` as the Grafana username. Decrypt the Grafana password with:

```bash
sops decrypt --extract '["observability"]["grafana-environment"]' secrets/homelab.yaml
```

Configure applications sending OTLP telemetry with:

```text
OTEL_TRACES_EXPORTER=otlp
OTEL_LOGS_EXPORTER=otlp
OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp.sacha.house
OTEL_EXPORTER_OTLP_HEADERS=Authorization=Basic%20<base64-credentials>
DEPLOYMENT_ENVIRONMENT=production
```

Generate the Base64 credentials without writing the password to disk:

```bash
OTLP_PASSWORD="$(sops decrypt --extract '["observability"]["otlp-password"]' secrets/homelab.yaml)"
printf 'froment:%s' "$OTLP_PASSWORD" | base64 -w0
unset OTLP_PASSWORD
```

The proxy accepts OTLP/HTTP with protobuf on `/v1/traces`, `/v1/logs`, and `/v1/metrics`.

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
sudo nixos-rebuild switch --flake /data/Home/sacha/Projects/nixconfig#homelab
```

## Fresh Install

Boot a NixOS ISO, clone the repo, then run the host's disko config.

Warning: disko is destructive. Verify the target disk in `hosts/<host>/disko.mod.nix` before running it.

### Install `homelab` from the NixOS ISO

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

The first `bootstrapAge` call seeds the activation key into `/mnt/persist/var/lib/sops-nix/key.txt` and `/mnt/var/lib/sops-nix/key.txt` so `nixos-install` can decrypt secrets. The second call after reboot installs the key for user editing as well.

## Secure Boot

Workstations (`house-desktop`, `house-laptop`) use Limine with Secure Boot (`sbctl`). Servers (`homelab`) and `kids-desktop` use `systemd-boot` without Secure Boot.

Generate and enroll Secure Boot keys on a workstation:

```bash
nix shell nixpkgs#sbctl
sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft
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

## Updating Packages

The inputs are tack pins in `.tack/pins.toml`, locked in `.tack/pins.lock.json`.
Use `tack look` to see available updates, and `tack undo` to revert the last update.

Update the inputs and hand-pinned packages:

```bash
nix run .#update
```

Or update only `opencode2` from `llm-agents`:

```bash
tack update llm-agents
nix build 'path:/home/sacha/Projects/nixconfig#opencode2' --no-link
```
