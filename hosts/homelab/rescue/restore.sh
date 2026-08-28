#!/usr/bin/env bash
set -euo pipefail

external_uuid=2d856b6e-e4bf-410e-af31-a640924a8bff
external_device=/dev/disk/by-id/ata-Samsung_Portable_SSD_T5_S4B1NR0N917150Y-part1
internal_disk=/dev/disk/by-id/nvme-INTEL_SSDPEKNW512G8H_PHNH9274019T512A
internal_esp=/dev/disk/by-id/nvme-INTEL_SSDPEKNW512G8H_PHNH9274019T512A-part1
migration_name=migration-2026-08-28
run_root=/run/homelab-storage-restore
external_mount=$run_root/external
storage_mount=$run_root/storage
target=/mnt
repo=/root/nixconfig

if [[ $EUID -ne 0 ]]; then
  exec sudo "$0" "$@"
fi

if [[ $(findmnt -no UUID /) != "$external_uuid" ]]; then
  echo "The restore must run from the external rescue system." >&2
  exit 1
fi
if [[ ! -d $repo/.git ]]; then
  echo "Missing rescue repository: $repo" >&2
  exit 1
fi
if [[ ! -b $external_device || ! -b $internal_disk || ! -b $internal_esp ]]; then
  echo "A required block device is missing." >&2
  exit 1
fi
if [[ $(blkid -s UUID -o value "$internal_esp") != 1E38-F67E ]]; then
  echo "The EFI partition UUID does not match." >&2
  exit 1
fi

disk_serial=$(udevadm info --query=property --name="$internal_disk" | sed -n 's/^ID_SERIAL_SHORT=//p')
if [[ $disk_serial != PHNH9274019T512A ]]; then
  echo "The internal NVMe serial does not match." >&2
  exit 1
fi

mkdir -p "$external_mount" "$storage_mount"
mount -o subvolid=5,ro "$external_device" "$external_mount"
migration_root=$external_mount/$migration_name
manifest=$migration_root/manifest.tsv
if [[ ! -f $migration_root/COMPLETE || ! -f $manifest || ! -f $migration_root/manifest.sha256 ]]; then
  echo "The migration backup is incomplete." >&2
  exit 1
fi
(cd "$migration_root" && sha256sum --check manifest.sha256)

declare -A present=()
while IFS=$'\t' read -r group name source_uuid received_uuid; do
  if [[ $group == group ]]; then
    continue
  fi
  snapshot=$migration_root/$group/$name
  if [[ $group != system && $group != data ]] || [[ ! -d $snapshot ]]; then
    echo "Invalid backup inventory entry: $group/$name" >&2
    exit 1
  fi
  actual_received_uuid=$(btrfs subvolume show "$snapshot" | awk '$1 == "Received" && $2 == "UUID:" {print $3}')
  readonly=$(btrfs property get -ts "$snapshot" ro | sed -n 's/^ro=//p')
  if [[ $source_uuid != "$received_uuid" || $actual_received_uuid != "$received_uuid" || $readonly != true ]]; then
    echo "Invalid received subvolume: $group/$name" >&2
    exit 1
  fi
  present[$group/$name]=1
done <"$manifest"

required=(
  system/nix
  system/persist
  data/@data
  data/@data-agents
  data/@data-backups
  data/@data-docker-appdata
  data/@data-docker-backup
  data/@data-docker-data
  data/@data-docker-storage
  data/@data-downloads
  data/@data-github-runner
  data/@data-home
  data/@data-media
  data/@data-secrets
  data/@data-tmp
  data/@data-vms
)
for name in "${required[@]}"; do
  if [[ -z ${present[$name]:-} ]]; then
    echo "Required backup subvolume is missing: $name" >&2
    exit 1
  fi
done

echo "Building the final NixOS closure before disk changes."
nix build "path:$repo#nixosConfigurations.homelab.config.system.build.toplevel" --no-link
btrfs device stats -c "$external_mount"

swapoff --all
internal_disk_real=$(realpath "$internal_disk")
for number in 2 3 4; do
  partition=${internal_disk_real}p$number
  if findmnt -rn -S "$partition" >/dev/null; then
    echo "The internal partition is still mounted: $partition" >&2
    exit 1
  fi
  if [[ -d /sys/class/block/$(basename "$partition")/holders ]] &&
    compgen -G "/sys/class/block/$(basename "$partition")/holders/*" >/dev/null; then
    echo "The internal partition still has holders: $partition" >&2
    exit 1
  fi
done

if mountpoint -q "$target" || mountpoint -q "$storage_mount"; then
  echo "A restore mountpoint is already active." >&2
  exit 1
fi

echo "This operation will erase partitions 2, 3, and 4 on $internal_disk."
if [[ ${1:-} != --yes ]]; then
  read -r -p 'Type ERASE-NVME to continue: ' confirmation
  if [[ $confirmation != ERASE-NVME ]]; then
    echo "Cancelled."
    exit 1
  fi
fi

for number in 4 3 2; do
  if [[ -b ${internal_disk_real}p$number ]]; then
    sgdisk --delete="$number" "$internal_disk"
  fi
done
sgdisk --new=2:0:0 --typecode=2:8300 --change-name=2:homelab "$internal_disk"
partprobe "$internal_disk"
udevadm settle

storage_device=$internal_disk-part2
mkfs.btrfs -f -L homelab "$storage_device"
mount -o subvolid=5 "$storage_device" "$storage_mount"

while IFS=$'\t' read -r group name _; do
  if [[ $group == group ]]; then
    continue
  fi
  btrfs send "$migration_root/$group/$name" | btrfs receive "$storage_mount"
  btrfs property set -f -ts "$storage_mount/$name" ro false
done <"$manifest"

btrfs subvolume create "$storage_mount/@swap"
mkdir -p "$target"
mount -t tmpfs -o size=25%,mode=755 none "$target"

mount_subvolume() {
  local name=$1
  local path=$2
  local options=$3
  mkdir -p "$target$path"
  mount -o "subvol=$name,$options" "$storage_device" "$target$path"
}

mount_subvolume nix /nix compress=zstd,noatime
mount_subvolume persist /persist compress=zstd,noatime
mount_subvolume @data /data compress=zstd,noatime,space_cache=v2
mount_subvolume @data-agents /data/Agents compress=zstd,noatime
mount_subvolume @data-backups /data/Backups compress=zstd,noatime
mount_subvolume @data-docker-appdata /data/Docker/appdata compress=zstd,noatime
mount_subvolume @data-docker-backup /data/Docker/backup compress=zstd,noatime
mount_subvolume @data-docker-data /data/Docker/data compress=zstd,noatime
mount_subvolume @data-docker-storage /data/Docker/storage compress=zstd:1,noatime
mount_subvolume @data-downloads /data/Downloads compress=zstd:3,noatime
mount_subvolume @data-home /data/Home compress=zstd,noatime
mount_subvolume @data-github-runner /var/lib/github-runner compress=zstd:1,noatime
mount_subvolume @data-media /data/Media compress=zstd:1,noatime
mount_subvolume @data-secrets /data/Secrets compress=zstd,noatime
mount_subvolume @data-tmp /tmp compress=zstd:1,noatime
mount_subvolume @data-vms /data/VMs compress=zstd:1,noatime
mount_subvolume @swap /.swap noatime

btrfs filesystem mkswapfile --size 16G "$target/.swap/swapfile"
mkdir -p "$target/boot"
mount "$internal_esp" "$target/boot"

nixos-install --root "$target" --flake "path:$repo#homelab" --no-root-passwd
sync

echo "Restore completed. Reboot into the latest homelab generation."
