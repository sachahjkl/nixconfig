#!/usr/bin/env bash
set -euo pipefail

external_device=/dev/disk/by-id/ata-Samsung_Portable_SSD_T5_S4B1NR0N917150Y-part1
system_device=/dev/disk/by-id/nvme-INTEL_SSDPEKNW512G8H_PHNH9274019T512A-part2
data_device=/dev/disk/by-id/nvme-INTEL_SSDPEKNW512G8H_PHNH9274019T512A-part4
migration_name=migration-2026-08-28
run_root=/run/homelab-storage-migration
external_mount=$run_root/external
system_mount=$run_root/system
data_mount=$run_root/data
backup_complete=false

if [[ $EUID -ne 0 ]]; then
  exec sudo "$0" "$@"
fi

running_services=()

restart_services() {
  if [[ $backup_complete == false ]] && ((${#running_services[@]})); then
    systemctl start "${running_services[@]}"
  fi
}

cleanup() {
  local status=$?
  restart_services
  mountpoint -q "$data_mount" && umount "$data_mount"
  mountpoint -q "$system_mount" && umount "$system_mount"
  mountpoint -q "$external_mount" && umount "$external_mount"
  rmdir "$data_mount" "$system_mount" "$external_mount" "$run_root" 2>/dev/null || true
  exit "$status"
}
trap cleanup EXIT

for device in "$external_device" "$system_device" "$data_device"; do
  if [[ ! -b $device ]]; then
    echo "Missing block device: $device" >&2
    exit 1
  fi
done

mkdir -p "$external_mount" "$system_mount" "$data_mount"
mount -o subvolid=5,noatime "$external_device" "$external_mount"
mount -o subvolid=5,noatime "$system_device" "$system_mount"
mount -o subvolid=5,noatime "$data_device" "$data_mount"

migration_root=$external_mount/$migration_name
if [[ -e $migration_root ]]; then
  echo "Migration backup already exists: $migration_root" >&2
  exit 1
fi

mkdir -p "$migration_root/system" "$migration_root/data"
system_snapshots=$system_mount/.migration-snapshots
data_snapshots=$data_mount/.migration-snapshots
mkdir -p "$system_snapshots" "$data_snapshots"

list_top_level_subvolumes() {
  btrfs subvolume list "$1" | sed -n 's/.* top level 5 path //p' | sort
}

mapfile -t system_names < <(list_top_level_subvolumes "$system_mount")
mapfile -t data_names < <(list_top_level_subvolumes "$data_mount")
if btrfs subvolume list "$system_mount" | grep -qv ' top level 5 ' ||
  btrfs subvolume list "$data_mount" | grep -qv ' top level 5 '; then
  echo "Nested subvolumes require an explicit migration plan." >&2
  exit 1
fi
declare -A system_present=()
declare -A data_present=()
for name in "${system_names[@]}"; do
  system_present[$name]=1
done
for name in "${data_names[@]}"; do
  data_present[$name]=1
done

if [[ -z ${system_present[nix]:-} || -z ${system_present[persist]:-} ]]; then
  echo "The system filesystem lacks nix or persist." >&2
  exit 1
fi

required_data=(
  @data
  @data-agents
  @data-backups
  @data-docker-appdata
  @data-docker-backup
  @data-docker-data
  @data-docker-storage
  @data-downloads
  @data-github-runner
  @data-home
  @data-media
  @data-secrets
  @data-tmp
  @data-vms
)
for name in "${required_data[@]}"; do
  if [[ -z ${data_present[$name]:-} ]]; then
    echo "Missing data subvolume: $name" >&2
    exit 1
  fi
done

services=(
  albumator.service
  clockin.service
  docker.service
  filebrowser.service
  libvirtd.service
  nginx.service
  nfs-server.service
  restic-backups-homelab.service
  sacha-house.service
  samba-smbd.service
)
mapfile -t runner_services < <(systemctl list-units 'github-runner-*.service' --state=running --no-legend | awk '{print $1}')
services+=("${runner_services[@]}")

for service in "${services[@]}"; do
  if systemctl is-active --quiet "$service"; then
    running_services+=("$service")
  fi
done

if ((${#running_services[@]})); then
  systemctl stop "${running_services[@]}"
fi
sync

for name in "${system_names[@]}"; do
  btrfs subvolume snapshot -r "$system_mount/$name" "$system_snapshots/$name"
done
for name in "${data_names[@]}"; do
  btrfs subvolume snapshot -r "$data_mount/$name" "$data_snapshots/$name"
done

for snapshot in "$system_snapshots"/*; do
  btrfs send "$snapshot" | btrfs receive "$migration_root/system"
done
for snapshot in "$data_snapshots"/*; do
  btrfs send "$snapshot" | btrfs receive "$migration_root/data"
done

manifest=$migration_root/manifest.tsv
printf 'group\tname\tsource_uuid\treceived_uuid\n' >"$manifest"
for group in system data; do
  source_directory=${group}_snapshots
  source_directory=${!source_directory}
  for source in "$source_directory"/*; do
    name=$(basename "$source")
    received=$migration_root/$group/$name
    source_uuid=$(btrfs subvolume show "$source" | awk '$1 == "UUID:" {print $2}')
    received_uuid=$(btrfs subvolume show "$received" | awk '$1 == "Received" && $2 == "UUID:" {print $3}')
    if [[ -z $source_uuid || $received_uuid != "$source_uuid" ]]; then
      echo "Received UUID mismatch: $group/$name" >&2
      exit 1
    fi
    printf '%s\t%s\t%s\t%s\n' "$group" "$name" "$source_uuid" "$received_uuid" >>"$manifest"
  done
done

sync
btrfs scrub start -B "$external_mount"
btrfs device stats -c "$external_mount"
(cd "$migration_root" && sha256sum manifest.tsv >manifest.sha256)
printf 'Completed: %s\n' "$(date --iso-8601=seconds)" >"$migration_root/COMPLETE"
sync

for snapshot in "$system_snapshots"/* "$data_snapshots"/*; do
  btrfs subvolume delete "$snapshot"
done
rmdir "$system_snapshots" "$data_snapshots"

backup_complete=true
echo "Migration backup completed: $migration_root"
echo "Application services remain stopped. Reboot into homelab-rescue now."
