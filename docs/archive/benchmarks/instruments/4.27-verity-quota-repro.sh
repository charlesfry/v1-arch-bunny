#!/usr/bin/env bash
# Reproduce the 4.27 forced-readonly inside a loopback btrfs image.
#
# WHY THIS EXISTS: on 2026-08-25 a synthetic qgroup cap on `@containerd` took
# `bunne-test`'s ENTIRE filesystem read-only -- `/` and `/home` with it, because a
# qgroup limit is scoped to a subvolume while forced-readonly is scoped to the
# filesystem. That was n=1 on a machine only the author can unlock, and
# `benchmarks/4.26`'s rule is to reproduce an alarming result on purpose before
# recording it. Here the blast radius is a loop device.
#
# THE MECHANISM: btrfs writes an fs-verity Merkle tree when verity is enabled on a
# file. If that write is denied, btrfs must roll the verity items back -- and
# dropping them needs metadata space, which the same quota also denies. A rollback
# that cannot complete is not recoverable, so btrfs aborts and forces the
# filesystem read-only (`rollback_verity:459`, errno -122).
#
# containerd puts fs-verity on its content, which is how Docker reaches this path.
#
#   (default)     quota denies the Merkle tree write  -> expect forced readonly
#   --control     NO quota, filesystem genuinely full -> ENOSPC path, for comparison
#   --accounting  quota enabled, NO limit             -> expect verity to SUCCEED
#
# `--accounting` is the configuration question 26 answered with (author, 2026-08-26:
# drop the caps, keep the qgroups for the C9 alert's numbers). It exists because that
# answer rests on "the *limit* is the trigger, not the accounting", and this repo does
# not ship a safety argument it has not run. Expect: verity ENABLED, filesystem `rw`.
#
# Usage: 4.27-verity-quota-repro.sh [--control|--accounting] [--help]
set -Eeuo pipefail

control=false
accounting=false
case "${1-}" in
--control) control=true ;;
--accounting) accounting=true ;;
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit 0
	;;
'') ;;
*)
	echo "unknown: $1" >&2
	exit 1
	;;
esac

command -v mkfs.btrfs >/dev/null || {
	echo "need btrfs-progs" >&2
	exit 1
}

img=$(mktemp -p /var/tmp verity-repro-XXXXXX.img)
mnt=$(mktemp -d)
cleanup() {
	sudo umount "$mnt" 2>/dev/null || true
	rmdir "$mnt" 2>/dev/null || true
	sudo rm -f "$img"
}
trap cleanup EXIT

# Enabling verity on a 200 MiB file needs roughly 1.6 MB of Merkle tree
# (200 MiB / 4096-byte blocks x 32-byte SHA-256 digests, plus upper levels).
size=$($control && echo 700M || echo 3G)
truncate -s "$size" "$img"
sudo mkfs.btrfs -q -f "$img" >/dev/null
sudo mount -o loop "$img" "$mnt"
$control || sudo btrfs quota enable "$mnt"
sudo btrfs subvolume create "$mnt/sub" >/dev/null
sudo dd if=/dev/urandom of="$mnt/sub/big" bs=1M count=200 status=none

if $accounting; then
	# Quota on for accounting, no limit set: nothing to deny the Merkle write.
	# `sync` first: qgroup figures count committed extents, so a read without it
	# reported 16 KiB for a subvolume holding 200 MiB (observed 2026-08-26).
	sudo sync
	sudo btrfs quota rescan -w "$mnt" >/dev/null 2>&1 || true
	echo "quota enabled, no limit:"
	sudo btrfs qgroup show --raw -re "$mnt" | tail -2
elif $control; then
	# Deny the space by filling the filesystem instead of by quota.
	sudo dd if=/dev/urandom of="$mnt/sub/filler" bs=1M status=none 2>/dev/null || true
	sudo sync 2>/dev/null || true
	df -h "$mnt" | tail -1
else
	local_qid=$(sudo btrfs subvolume show "$mnt/sub" | awk '/Subvolume ID:/{print "0/"$3}')
	sudo btrfs qgroup limit 1G "$local_qid" "$mnt"
	sudo sync
	sudo btrfs quota rescan -w "$mnt" >/dev/null 2>&1 || true
	# Leave 64 KiB of headroom: far less than the Merkle tree needs.
	used_k=$(sudo btrfs qgroup show --raw -re "$mnt" |
		awk -v q="$local_qid" '$1==q{print int($2/1024)}')
	echo "used=${used_k}K, limit=$((used_k + 64))K (64K headroom, tree needs ~1600K)"
	sudo btrfs qgroup limit "$((used_k + 64))K" "$local_qid" "$mnt"
fi

echo "--- enabling fs-verity"
sudo python3 - "$mnt/sub/big" <<'PY'
import fcntl, struct, sys, os
# FS_IOC_ENABLE_VERITY = _IOW('f', 133, struct fsverity_enable_arg) = 0x40806685
# struct: version, hash_algorithm(1=SHA-256), block_size, salt_size, salt_ptr,
#         sig_size, __reserved1, sig_ptr, __reserved2[11]
arg = struct.pack('=IIII Q II Q 11Q', 1, 1, 4096, 0, 0, 0, 0, 0, *([0] * 11))
fd = os.open(sys.argv[1], os.O_RDONLY)
try:
	fcntl.ioctl(fd, 0x40806685, arg)
	print("verity ENABLED (the write was not denied)")
except OSError as e:
	print(f"verity ioctl failed: errno={e.errno} {e.strerror}")
finally:
	os.close(fd)
PY

echo "--- loop filesystem is now:"
findmnt -no OPTIONS "$mnt" | tr ',' '\n' | grep -E '^(ro|rw)$' || echo "(not mounted)"
if sudo dmesg | grep -q "forced readonly"; then
	echo "RESULT: forced readonly REPRODUCED"
else
	echo "RESULT: not forced readonly"
fi
sudo dmesg | grep -iE 'rollback_verity|forced readonly' | tail -3 || true
