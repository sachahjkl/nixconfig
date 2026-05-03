# Dotfiles / NixOS config

## Rebuild

For the desktop:

```bash
sudo nixos-rebuild switch --flake /home/sacha/Devel/dotfiles#house-desktop
```

For the laptop:

```bash
sudo nixos-rebuild switch --flake /home/sacha/Devel/dotfiles#house-laptop
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
sudo nixos-rebuild boot --flake /home/sacha/Devel/dotfiles#house-desktop
```

### 5. Verify signatures and Secure Boot state

```bash
nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#sbctl -c sudo sbctl verify
bootctl status
```

### 6. Re-enable Secure Boot

If your firmware disables Secure Boot while in Setup Mode, re-enable it before the final reboot.
