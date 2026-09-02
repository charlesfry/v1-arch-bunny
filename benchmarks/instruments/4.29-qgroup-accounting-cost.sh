#!/usr/bin/env bash
# What does btrfs qgroup accounting cost when it enforces nothing?
#
# WHY THIS EXISTS: open question 26 was answered by dropping the Docker qgroup
# *limits* and keeping the qgroups, because `disk-alert`'s meter 2 reads them for
# per-subvolume byte figures. That leaves `btrfs quota` enabled on a filesystem
# where it no longer protects anything -- it buys one number in a notification
# that fires six times a day. btrfs charges for qgroup accounting on metadata
# operations, so open question 28 asks whether that trade is worth making. This
# measures it instead of guessing.
#
# THE SHAPE OF THE TEST: a loopback btrfs holding a populated subvolume and 24
# snapshots of it -- `bunne-test`'s actual qgroup count, which matters because
# qgroup accounting walks the sharing relationships between them. Three timed
# metadata-heavy operations per run, the same ones this machine really does:
#
#   extract   untar a 7675-file kernel package (pacman's own workload)
#   delete    rm -rf it again
#   snapshot  btrfs subvolume snapshot + sync
#   subvoldel delete 5 snapshots and wait for the cleaner -- the case that
#             actually matters, because `snapshot-system` sets NUMBER_LIMIT=2-15
#             and snapper therefore deletes snapshots routinely, and qgroup
#             accounting on snapshot deletion is btrfs's known slow path
#
# Arms alternate rather than blocking, so machine drift lands on both equally.
# Each run gets a fresh image, so no run inherits another's fragmentation.
#
# Data to stdout as TSV (arm, run, extract, delete, snapshot -- seconds);
# progress to stderr. Medians are left to the caller:
#
#   ./4.29-qgroup-accounting-cost.sh --runs 5 >4.29.tsv
#   awk -F'\t' 'NR>1{a[$1"\t"i]=0; s[$1]++} ...'   # or just sort | datamash
#
# Usage: 4.29-qgroup-accounting-cost.sh [--runs N] [--seed PKG] [--help]
set -Eeuo pipefail
export LC_ALL=C # EPOCHREALTIME's decimal separator, and awk's

runs=5
seed=/var/cache/pacman/pkg/linux-7.1.9.arch1-2-x86_64.pkg.tar.zst

while (($#)); do
	case "$1" in
	--runs)
		runs=$2
		shift 2
		;;
	--seed)
		seed=$2
		shift 2
		;;
	-h | --help)
		sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
		exit 0
		;;
	*)
		echo "unknown: $1" >&2
		exit 1
		;;
	esac
done

[[ -r $seed ]] || {
	echo "seed not readable: $seed" >&2
	exit 1
}

mnt=$(mktemp -d)
img=
cleanup() {
	sudo umount "$mnt" 2>/dev/null || true
	rmdir "$mnt" 2>/dev/null || true
	# Not `[[ -n $img ]] && rm`: as the last command in an EXIT trap its status
	# becomes the script's, so a cleared $img exited 1 on a successful run.
	if [[ -n $img ]]; then sudo rm -f "$img"; fi
}
trap cleanup EXIT

# Elapsed seconds between two EPOCHREALTIME reads.
elapsed() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.3f", b - a }'; }

# One run: build the filesystem, then time three operations on it.
run_once() {
	local quota=$1
	img=$(mktemp -p /var/tmp qgroup-cost-XXXXXX.img)
	truncate -s 8G "$img"
	sudo mkfs.btrfs -q -f "$img"
	sudo mount -o loop,noatime,compress=zstd:1 "$img" "$mnt"

	# Base content, so the snapshots below share real extents rather than nothing.
	sudo btrfs subvolume create "$mnt/@" >/dev/null
	sudo tar -xf "$seed" -C "$mnt/@"
	sudo sync
	# A workload that silently extracted nothing would time the empty case and
	# report it as a result -- the `docker-storage-quota` canary lesson.
	local files
	files=$(sudo find "$mnt/@" -type f | wc -l)
	((files > 1000)) || {
		echo "seed extracted only $files files -- refusing to time nothing" >&2
		exit 1
	}
	echo "  base: $files files" >&2

	if [[ $quota == on ]]; then
		sudo btrfs quota enable "$mnt"
		sudo btrfs quota rescan -w "$mnt" >/dev/null
	fi

	# 24 snapshots: bunne-test's count on 2026-08-26. Made *after* the quota
	# decision so each one is accounted the way a real snapper snapshot is.
	local i
	for i in $(seq 24); do
		sudo btrfs subvolume snapshot "$mnt/@" "$mnt/snap-$i" >/dev/null
	done
	sudo sync

	local t0 t1 t2 t3 t4 t5 t6 t7
	t0=$EPOCHREALTIME
	sudo tar -xf "$seed" -C "$mnt/@" --one-top-level=w
	sudo sync
	t1=$EPOCHREALTIME

	t2=$EPOCHREALTIME
	sudo rm -rf "$mnt/@/w"
	sudo sync
	t3=$EPOCHREALTIME

	t4=$EPOCHREALTIME
	sudo btrfs subvolume snapshot "$mnt/@" "$mnt/snap-timed" >/dev/null
	sudo sync
	t5=$EPOCHREALTIME

	# `-C` waits for the transaction commit that actually processes the dead
	# roots, which is where the qgroup work lands. Do NOT use `btrfs subvolume
	# sync` here: measured 2026-08-26, a plain delete returns in 0.02 s and the
	# subvolumes leave the list in 0.04 s, but `subvolume sync` then blocks a
	# flat ~29 s in BOTH arms -- it measures its own polling, not the filesystem.
	t6=$EPOCHREALTIME
	sudo btrfs subvolume delete -C "$mnt"/snap-{1,2,3,4,5} >/dev/null
	t7=$EPOCHREALTIME

	printf '%s\t%s\t%s\t%s\t%s\n' "$quota" \
		"$(elapsed "$t0" "$t1")" "$(elapsed "$t2" "$t3")" \
		"$(elapsed "$t4" "$t5")" "$(elapsed "$t6" "$t7")"

	sudo umount "$mnt"
	sudo rm -f "$img"
	img=
}

command -v mkfs.btrfs >/dev/null || {
	echo "need btrfs-progs" >&2
	exit 1
}

printf 'quota\trun\textract\tdelete\tsnapshot\tsubvoldel\n'
for ((r = 1; r <= runs; r++)); do
	for arm in on off; do
		echo "run $r/$runs, quota=$arm" >&2
		line=$(run_once "$arm")
		printf '%s\t%s\t%s\n' "${line%%$'\t'*}" "$r" "${line#*$'\t'}"
	done
done
