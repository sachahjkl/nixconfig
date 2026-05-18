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

The `disko.nix` file for your host must define:

- an ESP partition (1G, FAT32, mounted at `/boot`)
- optionally a swap partition with `resumeDevice = true`
- a LUKS-encrypted root partition containing a Btrfs filesystem
- Btrfs subvolumes `/persist` and `/nix` (mounted with `subvol=persist` / `subvol=nix`)
- a tmpfs for `/` (size 25%, mode 755)

The `house-desktop` disko already has Btrfs subvolumes and tmpfs root.
To add LUKS, wrap the `content` of the root partition:

```nix
root = {
  size = "100%";
  content = {
    type = "luks";
    name = "cryptroot";
    settings.allowDiscards = true;
    content = {
      type = "btrfs";
      extraArgs = [ "-f" ];
      subvolumes = {
        # ... subvolumes as before ...
      };
    };
  };
};
```

### Boot configuration

In your base or host NixOS module:

```nix
boot.initrd.systemd.enable = true;
boot.initrd.luks.devices.cryptroot = {
  device = "/dev/disk/by-partlabel/cryptroot";
  allowDiscards = true;
  crypttabExtraOpts = [ "fido2-device=auto" ];
};
```

### Install steps

```bash
# 1. Clone repo
cd /root
git clone https://github.com/your-user/your-repo Projects/nixconfig

# 2. Run disko (DESTRUCTIVE – double check the disk path)
sudo nix run "github:nix-community/disko" -- --mode disko \
  /root/Projects/nixconfig#house-desktop

# 3. Verify the LUKS container exists
lsblk -f

# 4. Create a recovery passphrase on the LUKS container
sudo cryptsetup luksAddKey /dev/disk/by-partlabel/cryptroot

# 5. Enroll YubiKey for FIDO2 unlock
sudo systemd-cryptenroll \
  --fido2-device=auto \
  --fido2-with-user-presence=yes \
  /dev/disk/by-partlabel/cryptroot

# 6. Install NixOS
nixos-install --root /mnt --flake \
  "/root/Projects/nixconfig#house-desktop"
```

### Post-install verification

1. Reboot.
2. At the initrd prompt, test FIDO2 unlock (touch your YubiKey).
3. Test recovery passphrase unlock as fallback.
4. Once booted, re-enroll if you have a second YubiKey.

### Updating the recovery passphrase later

```bash
sudo cryptsetup luksChangeKey /dev/disk/by-partlabel/cryptroot
```

### Enrolling a second YubiKey

```bash
sudo systemd-cryptenroll \
  --fido2-device=auto \
  --fido2-with-user-presence=yes \
  /dev/disk/by-partlabel/cryptroot
```

### Notes

- FIDO2 unlock with `systemd` initrd requires `boot.initrd.systemd.enable = true`.
- The `luks.devices.<name>.crypttabExtraOpts` must include `fido2-device=auto` for passwordless FIDO2 prompt.
- Store at least one recovery passphrase offline (not only on a YubiKey).
- `preLVM` is not needed since LUKS wraps Btrfs directly, not LVM.

## Rebuild

```bash
nh os switch --hostname house-desktop
nh os switch --hostname house-laptop
```

Or directly:

```bash
sudo nixos-rebuild switch --flake /home/sacha/Projects/nixconfig#house-desktop
sudo nixos-rebuild switch --flake /home/sacha/Projects/nixconfig#house-laptop
```

## Verification

For in-progress work, especially with untracked files:

```bash
nix flake check "path:$PWD" --no-write-lock-file
```
