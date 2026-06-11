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
git clone git@gitlab.com:sachahjkl/nixconfig.git /home/sacha/Projects/nixconfig
cd /home/sacha/Projects/nixconfig
```

If the host uses agenix secrets, restore the dedicated agenix private key from Bitwarden:

```bash
install -m 700 -d ~/.ssh
$EDITOR ~/.ssh/agenix
chmod 600 ~/.ssh/agenix
```

The public key is declared in `modules/keys.mod.nix`. Do not use the YubiKey resident `sk-*` SSH key for agenix; agenix needs a normal decryptable SSH key.

For `house-desktop`, the committed password hash is stored at:

```text
hosts/house-desktop/password.hash
```

The host points the primary user at:

```nix
passwordHashFile = ./password.hash;
```

## Creating A Password Hash

Generate a yescrypt password hash:

```bash
nix shell nixpkgs#mkpasswd -c mkpasswd -m yescrypt
```

Write the hash to the password file:

```bash
printf '%s\n' '<hash>' > hosts/house-desktop/password.hash
```

Commit only the hash, not the plaintext password.

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

```bash
sudo nix --extra-experimental-features 'nix-command flakes' \
  run github:nix-community/disko -- \
  --mode destroy,format,mount \
  --flake 'path:/home/sacha/Projects/nixconfig#house-desktop'
```

Install:

```bash
sudo nixos-install --root /mnt --flake 'path:/home/sacha/Projects/nixconfig#house-desktop'
```

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
