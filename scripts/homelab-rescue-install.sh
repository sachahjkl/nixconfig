#!/usr/bin/env bash
set -euo pipefail

external_device=/dev/disk/by-id/ata-Samsung_Portable_SSD_T5_S4B1NR0N917150Y-part1
internal_esp=/dev/disk/by-id/nvme-INTEL_SSDPEKNW512G8H_PHNH9274019T512A-part1
run_root=/run/homelab-rescue-install
external_mount=$run_root/external
target=$run_root/target
repo=$(realpath "${1:-.}")

if [[ $EUID -ne 0 ]]; then
  exec sudo "$0" "$repo"
fi
if [[ ! -d $repo/.git ]]; then
  echo "Not a Git repository: $repo" >&2
  exit 1
fi
if [[ ! -b $external_device || ! -b $internal_esp ]]; then
  echo "A required block device is missing." >&2
  exit 1
fi

cleanup() {
  mountpoint -q "$target/boot" && umount "$target/boot"
  mountpoint -q "$target" && umount "$target"
  mountpoint -q "$external_mount" && umount "$external_mount"
  rmdir "$target/boot" "$target" "$external_mount" "$run_root" 2>/dev/null || true
}
trap cleanup EXIT

echo "Building homelab-rescue before changing the external filesystem."
nix build "path:$repo#nixosConfigurations.homelab-rescue.config.system.build.toplevel" --no-link

mkdir -p "$external_mount" "$target"
mount -o subvolid=5,noatime "$external_device" "$external_mount"
if [[ ! -e $external_mount/@nixos-rescue ]]; then
  btrfs subvolume create "$external_mount/@nixos-rescue"
fi
mount -o subvol=@nixos-rescue,compress=zstd,noatime "$external_device" "$target"
mkdir -p "$target/boot"
mount "$internal_esp" "$target/boot"

nixos-install --root "$target" --flake "path:$repo#homelab-rescue" --no-root-passwd
mkdir -p "$target/root/nixconfig"
rsync -a --delete "$repo/" "$target/root/nixconfig/"
sync

echo "Installed homelab-rescue entries:"
grep -il 'homelab-rescue' "$target/boot"/loader/entries/*.conf || true
