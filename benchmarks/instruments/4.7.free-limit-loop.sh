#!/usr/bin/env bash
# 4.7 — FREE_LIMIT at the SHIPPING value (0.2), on a loopback btrfs.
# Converts 4.1's caveat "FREE_LIMIT=0.2 never watched" without 190 GB of SSD
# writes. Stated limitation up front: a 10 GiB loop file is not the 249 GiB
# production fs — this proves the 0.2 semantics fire on a genuinely-low-disk
# filesystem, not production scale.
# Design: 10 GiB btrfs on a loop device, snapper config with floor-0 ranges,
# min-age 0, SPACE_LIMIT high (0.9, so it cannot be the trigger), FREE_LIMIT
# 0.2. Fill the LIVE fs (not snapshots) to ~85% so free < 20%, with two
# number-class snapshots pinning ~2 GiB. Run cleanup: FREE_LIMIT must drive
# deletion of pinned snapshots to reclaim free space.
set -Eeuo pipefail
log() { printf '\n== %s ==\n' "$*"; }
IMG=/root/freelimit-test.img
MNT=/mnt/freelimit-test
cleanup() {
  snapper -c freetest delete-config 2>/dev/null || true
  umount -R "$MNT" 2>/dev/null || true
  losetup -j "$IMG" | cut -d: -f1 | xargs -r losetup -d
  rm -f "$IMG"; rmdir "$MNT" 2>/dev/null || true
}
trap cleanup EXIT

log "setup: 10 GiB loop btrfs"
truncate -s 10G "$IMG"
LOOP=$(losetup -f --show "$IMG")
mkfs.btrfs -q "$LOOP"
mkdir -p "$MNT"
mount "$LOOP" "$MNT"
btrfs quota enable "$MNT"

log "snapper config (floor 0, min-age 0, SPACE_LIMIT 0.9, FREE_LIMIT 0.2)"
snapper --no-dbus -c freetest create-config --fstype btrfs "$MNT"
snapper --no-dbus -c freetest set-config 'TIMELINE_CREATE=no' 'NUMBER_CLEANUP=yes' \
  'NUMBER_LIMIT=0-15' 'NUMBER_LIMIT_IMPORTANT=0-5' 'NUMBER_MIN_AGE=0' \
  'SPACE_LIMIT=0.9' 'FREE_LIMIT=0.2'
snapper --no-dbus -c freetest setup-quota
grep -E '^(QGROUP|SPACE_LIMIT|FREE_LIMIT|NUMBER_LIMIT|NUMBER_MIN_AGE)=' /etc/snapper/configs/freetest

log "pin ~2 GiB in two number-class snapshots"
dd if=/dev/urandom of="$MNT/pin1.bin" bs=1M count=1024 conv=fsync status=none
snapper --no-dbus -c freetest create -c number -d pin1
rm "$MNT/pin1.bin"
dd if=/dev/urandom of="$MNT/pin2.bin" bs=1M count=1024 conv=fsync status=none
snapper --no-dbus -c freetest create -c number -d pin2
rm "$MNT/pin2.bin"

log "fill live fs to ~85% (free < 20% => FREE_LIMIT violated; SPACE_LIMIT 0.9 not violated)"
dd if=/dev/urandom of="$MNT/live-fill.bin" bs=1M count=6500 conv=fsync status=none || echo "(fill hit ENOSPC early - fine)"
btrfs quota rescan -w "$MNT" >/dev/null
btrfs filesystem usage -b "$MNT" | grep -E 'Free \(estimated\)'
snapper --no-dbus -c freetest list

log "cleanup number: FREE_LIMIT=0.2 must drive deletion"
snapper --no-dbus -c freetest cleanup number
snapper --no-dbus -c freetest list
btrfs subvolume sync "$MNT" >/dev/null 2>&1 || true
btrfs filesystem usage -b "$MNT" | grep -E 'Free \(estimated\)'
echo "=== 4.7 complete (teardown via trap) ==="
