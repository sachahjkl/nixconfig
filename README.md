# Dotfiles / NixOS config

## Structure

```
.
├── flake.nix                  # Flake entrypoint; imports all .nix files via importTree
├── parts.nix                  # flake-parts systems and module imports
├── theme.nix                  # Base16 theme definitions and terminal palette
├── wrappedPrograms/           # Wrapper constructors (mkGit, mkTerminal, mkRofi, etc.)
├── nixos/
│   ├── base/                  # Core system: bootloader, kernel, i18n, nix settings
│   │   ├── assets.nix         # sacha.theme, sacha.assets options
│   │   ├── external.nix       # External flake modules (disko, hjem, preservation, mt7927)
│   │   ├── preservation.nix   # sacha.preservation option definition
│   │   ├── shell.nix          # Shell-related base config
│   │   ├── system.nix         # sacha.nixConfigPath, bootloader, nix, virtualisation
│   │   └── user.nix           # sacha.userName, fullName, homeDirectory + user config
│   ├── extra/                 # Cross-cutting concerns
│   │   ├── formatter.nix      # nixpkgs-fmt via flake-parts
│   │   └── hjem.nix           # Home file management (face icon, session vars)
│   ├── features/              # Feature modules (self-contained options + config)
│   │   ├── brave.nix
│   │   ├── desktop.nix        # desktop.environment option (hyprland/kde/both/niri)
│   │   ├── direnv.nix
│   │   ├── face-icon/
│   │   ├── firefox.nix
│   │   ├── fish.nix           # Fish preservation
│   │   ├── flatpak.nix
│   │   ├── gaming.nix
│   │   ├── hyprland/          # Split Hyprland: core, config, apps, waybar, dunst, lock, scripts, packages
│   │   ├── lf.nix             # lf config via hjem + preservation
│   │   ├── mimeapps.nix       # Default application associations
│   │   ├── neovim.nix
│   │   ├── niri.nix
│   │   ├── obs-studio.nix
│   │   ├── packages.nix       # Shared system packages + sacha.git options
│   │   ├── ssh.nix            # SSH config + sacha.ssh.identityKey option
│   │   ├── steam.nix
│   │   ├── sublime.nix        # Sublime Text + OpenSSL 1.1.1 permit
│   │   ├── wallpaper/
│   │   ├── wireplumber.nix
│   │   └── zoxide.nix
│   └── hosts/                 # Host-specific configs
│       ├── house-desktop/     # NVIDIA, mt7927, hyprland+niri (both)
│       └── house-laptop/      # niri-only, power-saving kernel params
```

## Desktop environment

Set `desktop.environment` in the host config:

- `"hyprland"` — Hyprland + SDDM (with UWSM)
- `"niri"` — Niri compositor
- `"both"` — both sessions available in SDDM

Desktop is set to `"both"` on house-desktop, `"niri"` on house-laptop.

## Options

All options are colocated in the modules that use them (vimjoyer pattern):

| Option | Module |
|---|---|
| `sacha.userName` | `nixos/base/user.nix` |
| `sacha.fullName` | `nixos/base/user.nix` |
| `sacha.homeDirectory` | `nixos/base/user.nix` |
| `sacha.nixConfigPath` | `nixos/base/system.nix` |
| `sacha.theme` | `nixos/base/assets.nix` |
| `sacha.assets` | `nixos/base/assets.nix` |
| `sacha.ssh.identityKey` | `nixos/features/ssh.nix` |
| `sacha.git.authorName` | `nixos/features/packages.nix` |
| `sacha.git.authorEmail` | `nixos/features/packages.nix` |
| `sacha.kitty.useThemeColors` | `wrappedPrograms/kitty.nix` |
| `sacha.preservation.*` | `nixos/base/preservation.nix` |
| `desktop.environment` | `nixos/features/desktop.nix` |

## Wrapper constructors

Wrappers that depend on NixOS config are built via `flake.lib` constructors, called from NixOS modules:

| Constructor | File | Used by |
|---|---|---|
| `mkGit { pkgs, authorName, authorEmail }` | `wrappedPrograms/git.nix` | `nixos/features/packages.nix` |
| `mkTerminal { pkgs, shell, useThemeColors }` | `wrappedPrograms/kitty.nix` | `nixos/extra/hjem.nix` |
| `mkRofi { pkgs, theme }` | `wrappedPrograms/rofi.nix` | Hyprland config, waybar, dunst |
| `mkHyprlock { pkgs, wallpaper, faceIcon }` | `wrappedPrograms/hyprlock.nix` | Hyprland lock |

## Rebuild

```bash
nh os switch --hostname house-desktop
nh os switch --hostname house-laptop
```

Or directly:

```bash
sudo nixos-rebuild switch --flake /home/sacha/Projects/dotfiles#house-desktop
sudo nixos-rebuild switch --flake /home/sacha/Projects/dotfiles#house-laptop
```

## Limine Secure Boot

This repo enables Limine with Secure Boot signing via `sbctl`.

### 1. Generate Secure Boot keys

```bash
nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#sbctl -c sudo sbctl create-keys
```

### 2. Put firmware into Setup Mode

Reboot into UEFI firmware settings and reset Secure Boot keys / enter Setup Mode.
The exact option name depends on the motherboard firmware.

### 3. Enroll keys

```bash
nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#sbctl -c sudo sbctl enroll-keys --microsoft --firmware-builtin
```

### 4. Install the signed Limine bootloader

```bash
sudo nixos-rebuild boot --flake /home/sacha/Projects/dotfiles#house-desktop
```

### 5. Verify signatures and Secure Boot state

```bash
nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#sbctl -c sudo sbctl verify
bootctl status
```

### 6. Re-enable Secure Boot

If your firmware disables Secure Boot while in Setup Mode, re-enable it before the final reboot.

## Flake-parts import model

All `.nix` files (except `flake.nix` and files prefixed with `_`) are imported as `flake-parts` modules via `importTree` in `flake.nix`. This means:

- Every file must export `flake.nixosModules.*`, `perSystem`, `flake.lib.*`, etc.
- Plain NixOS module fragments must be wrapped inside a `flake.nixosModules.<name>` export
- Host configs reference modules via `self.nixosModules.<name>`
