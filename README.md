# Dotfiles / NixOS config

## Structure

```
.
├── flake.nix
├── wrappedPrograms/
│   ├── user-shell.nix
│   ├── fish.nix
│   ├── git.nix
│   ├── kitty.nix
│   └── ...
└── nixos/
    ├── base/
    ├── extra/
    ├── features/
    │   └── hyprland/
    └── hosts/
```

## Architecture

This repo has five main layers:

1. `flake.nix`
2. flake-parts exports
3. NixOS modules
4. wrapped packages
5. host configs

### Big picture

```text
flake.nix
  -> imports every .nix file as a flake-parts module
  -> each file exports one or more of:
       - flake.nixosModules.<name>
       - perSystem.packages.<name>
       - flake.lib.mkThing
       - flake.wrappersModules.<name>

hosts/house-*/configuration.nix
  -> import aggregate modules like workstation / desktop / hyprland / niri
  -> set a few host-specific values
  -> produce nixosConfigurations.<host>

workstation / desktop / hyprland
  -> compose smaller feature modules

feature modules
  -> define options and/or apply config
  -> may call flake.lib.mkThing helpers

wrappedPrograms/*.nix
  -> define reusable wrapped binaries and wrapper modules
  -> expose either perSystem packages or flake.lib constructors
```

### Import model

`flake.nix` uses an import tree:

```nix
inputs.flake-parts.lib.mkFlake { inherit inputs; } {
  imports = importTree ./.;
}
```

That means every matching `.nix` file is imported as a `flake-parts` module, not as a plain NixOS module by default.

So a file in this repo usually exports one of these shapes:

```nix
{ ... }: {
  flake.nixosModules.someModule = { ... }: { ... };
}
```

```nix
{ ... }: {
  perSystem = { pkgs, ... }: {
    packages.somePackage = ...;
  };
}
```

```nix
{ ... }: {
  flake.lib.mkThing = args: ...;
}
```

## Module tree

### `nixos/base/`

Foundational system and identity pieces.

- `system.nix`: boot, kernel, locale, nix settings, virtualization, `nixConfigPath`
- `user.nix`: `userName`, `fullName`, `homeDirectory`, main user account
- `assets.nix`: `assets.*` and `preferences.theme.*`
- `preservation.nix`: `preferences.preservation.*` and mapping into upstream `preservation.*`
- `external.nix`: external modules re-exported into this repo

### `nixos/extra/`

Cross-cutting helpers.

- `hjem.nix`: exported here as `user-home`, wires home files/session variables
- `formatter.nix`: flake formatter output

### `nixos/features/`

Normal feature modules.

Small examples:

- `brave.nix`
- `firefox.nix`
- `nix.nix`
- `ssh.nix`
- `packages.nix`

Aggregate examples:

- `workstation.nix`: common host stack
- `desktop.nix`: shared desktop stack
- `hyprland/default.nix`: Hyprland aggregate
- `niri.nix`: Niri compositor module

### `nixos/hosts/`

Host entrypoints should stay thin.

They mostly:

1. import aggregates and host-specific modules
2. set host-only config
3. export `flake.nixosConfigurations.<host>`

Example shape:

```text
house-desktop
  -> workstation
  -> hyprland
  -> niri
  -> gaming
  -> hardware
```

## Wrapped packages

`wrappedPrograms/` is where command wrappers live.

There are two common patterns.

### Per-system wrapped packages

These export real packages under `perSystem.packages.*`.

Examples:

- `userShell`
- `lf`
- `nh`
- `nix-fast-build`
- `quickshell`

`userShell` is the main wrapped interactive shell environment, and it is also used as the login shell.

Example shape:

```nix
perSystem = { pkgs, ... }: {
  packages.lf = inputs.wrappers.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.lf;
  };
};
```

### `mkThing` constructors

These are helper functions exposed under `flake.lib.*`.

Use them when the wrapper depends on NixOS config values.

Examples:

- `mkGit`
- `mkTerminal`
- `mkRofi`
- `mkHyprlock`

Example flow:

```text
preferences.git.authorName
  -> nixos/features/packages.nix
  -> self.lib.mkGit { ... }
  -> wrapped git derivation
  -> added to environment.systemPackages
```

### Important wrapper idiom

The shell wrapper in `wrappedPrograms/user-shell.nix` is special because it builds a `PATH` for your interactive shell.

That means a plain package added there can shadow a wrapped package with the same executable name.

Rule of thumb:

- if this repo already exports a wrapped package for a command, prefer that wrapped package
- only add plain packages to the shell wrapper when there is no repo wrapper for them

## Options and preferences

The rule now is:

- use top-level options for machine/user identity or repo paths
- use `preferences.*` for user-tunable behavior

### Top-level options

- `userName`
- `fullName`
- `homeDirectory`
- `nixConfigPath`
- `assets.wallpaper`
- `assets.faceIcon`

### Preferences

- `preferences.theme.*`
- `preferences.kitty.useThemeColors`
- `preferences.git.authorName`
- `preferences.git.authorEmail`
- `preferences.ssh.identityKey`
- `preferences.preservation.*`

### Why `preferences.preservation.*` exists

The upstream module already owns the real `preservation.*` option tree.

This repo uses:

```text
preferences.preservation.*
  -> local preference/input layer
  -> nixos/base/preservation.nix
  -> translated into upstream preservation.*
```

So local feature modules can append persisted files/directories without colliding with the upstream module namespace.

## How composition works

This repo now prefers import-based composition instead of feature gating with booleans like `isHypr`.

That means:

- import `self.nixosModules.niri` if a host should have Niri
- import `self.nixosModules.hyprland` if a host should have Hyprland
- import both if a host should offer both sessions

This keeps modules normal and composable.

## Repo-specific idioms

### 1. Exported modules must evaluate standalone

`nix flake check` evaluates `flake.nixosModules.*` directly, not only through hosts.

So exported modules should not rely on some other module having already declared their options unless that dependency is explicit through imports.

That is one reason the repo now prefers plain import-based composition:

- `workstation` imports shared modules explicitly
- `desktop` imports shared desktop modules explicitly
- hosts import the compositor modules they want explicitly

### 2. Aggregate modules should compose, not hide magic

Good aggregate modules:

- `workstation`
- `desktop`
- `hyprland`

They are just named bundles of imports.

They should stay easy to read and should not become another hidden configuration language.

### 3. Thin hosts, fat features

Hosts should mostly answer:

- which aggregate stacks do I want?
- which compositor(s) do I want?
- what hardware or host-only overrides do I need?

Most reusable behavior should live below the host layer.

### 4. Keep scope boundaries clear

There are three different worlds in play:

1. `flake-parts` top-level exports
2. `perSystem` package/wrapper exports
3. NixOS module `config/options`

Typical rule:

- `self'` belongs to `perSystem`
- `selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system}` belongs inside NixOS modules when you want wrapped packages
- `config.*` belongs to NixOS module evaluation, not `perSystem`

## Diagram

```text
                         +----------------------+
                         |      flake.nix       |
                         | importTree over repo |
                         +----------+-----------+
                                    |
                +-------------------+-------------------+
                |                   |                   |
                v                   v                   v
      +----------------+   +----------------+   +-------------------+
      | flake.lib.*    |   | perSystem.*    |   | flake.nixosModules|
      | mkGit,         |   | wrapped pkgs   |   | base, desktop,    |
      | mkTerminal...  |   | userShell...   |   | hyprland, hosts   |
      +--------+-------+   +--------+-------+   +---------+---------+
               |                    |                     |
               |                    |                     |
               v                    |                     v
      +------------------+          |          +----------------------+
      | feature modules  |          |          | aggregate modules    |
      | packages.nix     |          |          | workstation,         |
      | ssh.nix          |          |          | desktop, hyprland    |
      +--------+---------+          |          +----------+-----------+
               |                    |                     |
               +--------------------+---------------------+
                                    |
                                    v
                        +--------------------------+
                        | hosts/house-*            |
                        | thin host composition    |
                        +------------+-------------+
                                     |
                                     v
                        +--------------------------+
                        | nixosConfigurations.*    |
                        +--------------------------+
```

## Current mental model

If you are deciding where something belongs:

1. Is it a reusable wrapped binary? Put it in `wrappedPrograms/`.
2. Does it depend on NixOS config values? Expose a `flake.lib.mkThing` helper.
3. Is it a small NixOS concern? Put it in `nixos/features/`.
4. Is it a common bundle of features? Make an aggregate module like `workstation` or `hyprland`.
5. Is it host-only? Keep it in `nixos/hosts/<host>/configuration.nix`.
6. Is it a user-facing knob? Prefer `preferences.*`.
7. Is it identity/path/foundation? Prefer top-level options.

## Reinstall With LUKS, Btrfs, And FIDO2

This is the encrypted reinstall procedure for a fresh disk.

### Prerequisites

- Boot a NixOS ISO with UEFI.
- Verify the target disk path with `ls -la /dev/disk/by-id/`.
- Disable Secure Boot in firmware during install (re-enable afterwards).

### Partitioning (disko)


it's a disko


### Install steps

```bash
# 1. Clone repo
cd /root
git clone https://github.com/your-user/your-repo Projects/nixconfig

cd /root/Projects/nixconfig

# 2. Run disko (DESTRUCTIVE — double check the disk path)
#
# The flake itself pins the exact disko revision through flake.lock.
sudo nix --extra-experimental-features 'nix-command flakes' \
  run github:nix-community/disko -- \
  --mode destroy,format,mount \
  --flake .#house-desktop

# 3. Verify mounts
mount | grep /mnt

# 4. Verify LUKS + Btrfs layout
lsblk -f

# 5. Verify enrolled credentials
sudo systemd-cryptenroll \
  /dev/disk/by-partlabel/cryptroot

# 6. Install NixOS
sudo nixos-install --root /mnt --flake .#house-desktop
```

### Expected layout

```text
disk
├─ ESP                 -> /boot
└─ cryptroot (LUKS2)
   └─ btrfs
      ├─ /persist
      ├─ /nix
      └─ /.swapvol/swapfile
```

### Post-install verification

1. Reboot.
2. Ensure initrd prompts for FIDO2 authentication.
3. Touch the YubiKey when prompted.
4. Verify fallback recovery/passphrase unlock still works.
5. Boot fully into the system.

### Enrolling an additional YubiKey

```bash
sudo systemd-cryptenroll \
  --fido2-device=auto \
  --fido2-with-user-presence=yes \
  --fido2-with-client-pin=yes \
  /dev/disk/by-partlabel/cryptroot
```

### Listing enrolled credentials

```bash
sudo systemd-cryptenroll \
  /dev/disk/by-partlabel/cryptroot
```

### Removing enrolled FIDO2 credentials

```bash
sudo systemd-cryptenroll \
  --wipe-slot=fido2 \
  /dev/disk/by-partlabel/cryptroot
```

### Adding or changing recovery passphrases

```bash
sudo cryptsetup luksAddKey \
  /dev/disk/by-partlabel/cryptroot
```

### Changing an existing recovery passphrase

```bash
sudo cryptsetup luksChangeKey \
  /dev/disk/by-partlabel/cryptroot
```

### Notes

- `boot.initrd.systemd.enable = true` is required for FIDO2 unlock.
- `enrollFido2 = true` automatically configures initrd FIDO2 unlock through `crypttabExtraOpts`.
- The disko input is pinned through `flake.lock` for reproducible installs.
- Keep at least one recovery passphrase.
- Keep a second enrolled YubiKey if possible.
- Your root filesystem is Btrfs inside LUKS2 (no LVM).
- Swap is encrypted automatically because the swapfile lives inside the encrypted Btrfs filesystem.
- `allowDiscards = true` enables SSD TRIM through LUKS.
- `/` is ephemeral tmpfs; persistent data must live under `/persist`.

## Rebuild

```bash
nh os switch --hostname house-desktop
nh os switch --hostname house-laptop
```

Or directly:

```bash
sudo nixos-rebuild switch \
  --flake /home/sacha/Projects/nixconfig#house-desktop

sudo nixos-rebuild switch \
  --flake /home/sacha/Projects/nixconfig#house-laptop
```

## Verification

For in-progress work, especially with untracked files:

```bash
nix flake check "path:$PWD" --no-write-lock-file
```


### Secure Boot / sbctl setup (Limine)

If Secure Boot is enabled while using Limine, installation will fail until Secure Boot keys are generated.

For dual-boot systems with Windows, generate keys while preserving Microsoft UEFI certificates:

```bash
sudo nix-shell -p sbctl

sudo sbctl create-keys
```

Then retry installation:

```bash
sudo nixos-install --root /mnt --flake .#house-desktop
```

### Verifying Secure Boot state

```bash
sudo sbctl status
```

### Enrolling Secure Boot keys in firmware

After first successful boot into NixOS:

```bash
sudo sbctl enroll-keys --microsoft
```

Then reboot and enable Secure Boot in UEFI/BIOS firmware settings if it is not already enabled.

### Signing Limine EFI binaries

Limine EFI binaries must be signed for Secure Boot.

Typical path:

```bash
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
```

Depending on the Limine installation layout, you may also need:

```bash
sudo sbctl sign -s /boot/EFI/Linux/liminex64.efi
```

Verify signed files:

```bash
sudo sbctl verify
```

### Notes

- `--microsoft` preserves compatibility with Windows bootloaders and Microsoft-signed EFI binaries.
- Without `--microsoft`, Windows may stop booting under Secure Boot.
- Limine does not provide automatic Secure Boot integration like `lanzaboote`.
- EFI binaries must remain signed after updates.
- Keep backups of `/etc/secureboot`.
