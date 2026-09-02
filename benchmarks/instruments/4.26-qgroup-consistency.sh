#!/usr/bin/env bash
# Does a btrfs qgroup byte cap still enforce while the accounting is marked
# "inconsistent"? And what puts it in that state on a normal BunnE machine?
#
# WHY: `docker-storage-quota` is the answer to gripes #1 and #2, and its whole
# mechanism is a qgroup byte cap. On 2026-08-25 the standing "WARNING: qgroup
# data inconsistent, rescan recommended" line reappeared after an ordinary
# `pacman -S`, and a cap canary that is refused when the accounting is clean was
# NOT refused while it was dirty. If that replicates, the cap stops protecting
# the disk after every package install until someone rescans -- which is the
# gripe, not the fix.
#
# Protocol, repeated N times, alternating so neither arm gets the fresh machine:
#   A  rescan -> assert consistent -> cap 8M -> write 64M incompressible
#   B  pacman-paired transaction -> assert inconsistent -> cap 8M -> write 64M
# Expected if the cap is honest: refused in BOTH arms.
#
# RESULT (2026-08-25, benchmarks/4.26): **arm B never fired.** Three runs of a
# pacman-paired transaction left the accounting CONSISTENT, so this script tests
# arm A and honestly reports arm B as untriggered rather than passing something
# it did not measure. The alarm that prompted it did not replicate: induced by
# hand, the cap refused at the byte in BOTH states.
#
# To reach the inconsistent state reliably you need `btrfs quota disable /` then
# `enable /` -- which this script deliberately does NOT do, because it also
# **destroys snapper's `1/0` qgroup and drops the docker caps**, while
# `/etc/snapper/configs/root` goes on pointing at a qgroup that no longer exists.
# That silently disables the SPACE_LIMIT/FREE_LIMIT half of `snapshot-system`.
# If you induce it by hand, afterwards you must:
#     sudo snapper -c root setup-quota
#     sudo btrfs qgroup limit 100G /var/lib/containerd
#     sudo btrfs qgroup limit 50G  /var/lib/docker
#     sudo btrfs quota rescan -w /
# Automating a step whose cleanup is that easy to forget is how a test rig eats a
# production mechanism, so it stays manual and stays written down here.
#
# Incompressible data is mandatory: the filesystem is compress=zstd:1 and a
# /dev/zero canary passes an 8 MiB cap while writing 32 MiB (see 4.24).
#
# Usage: 4.26-qgroup-consistency.sh [runs]     (default 2)
set -Eeuo pipefail

SUB=/var/lib/docker # @dockervol; cap restored to 50G at the end
CANARY="$SUB/.qgroup-canary"
CAP=8M
REAL_CAP=50G
RUNS=${1:-2}
# Two tiny, dependency-free packages to force snap-pac pre/post pairs. Removed
# at the end; neither is a BunnE decision.
PKGS=(tree sl)

cleanup() {
	sudo rm -f "$CANARY" 2>/dev/null || true
	sudo btrfs qgroup limit "$REAL_CAP" "$SUB" 2>/dev/null || true
	sudo pacman -Rns --noconfirm "${PKGS[@]}" >/dev/null 2>&1 || true
	sudo btrfs quota rescan -w / >/dev/null 2>&1 || true
}
trap cleanup EXIT

inconsistent() { sudo btrfs qgroup show -re / 2>&1 | grep -qi inconsistent; }

# Returns 0 if the cap REFUSED the write (what we want), 1 if it let it through.
canary() {
	sudo rm -f "$CANARY"
	sudo sync
	sudo btrfs qgroup limit "$CAP" "$SUB"
	local rc=0
	sudo dd if=/dev/urandom of="$CANARY" bs=1M count=64 conv=fsync status=none 2>/dev/null || rc=1
	local sz
	sz=$(sudo stat -c %s "$CANARY" 2>/dev/null || echo 0)
	sudo rm -f "$CANARY"
	sudo sync
	sudo btrfs qgroup limit "$REAL_CAP" "$SUB"
	echo "$rc $sz"
}

for i in $(seq 1 "$RUNS"); do
	echo "== run $i =="

	sudo btrfs quota rescan -w / >/dev/null 2>&1
	inconsistent && {
		echo "  A: could not reach a consistent state; aborting" >&2
		exit 1
	}
	read -r rc sz < <(canary)
	echo "  A consistent   -> dd rc=$rc, wrote $sz bytes against an $CAP cap $([ "$rc" = 1 ] && echo '(REFUSED, correct)' || echo '(ALLOWED -- cap did not bite)')"

	sudo pacman -S --noconfirm --needed "${PKGS[@]}" >/dev/null 2>&1
	sudo pacman -Rns --noconfirm "${PKGS[@]}" >/dev/null 2>&1
	if inconsistent; then
		read -r rc sz < <(canary)
		echo "  B inconsistent -> dd rc=$rc, wrote $sz bytes against an $CAP cap $([ "$rc" = 1 ] && echo '(REFUSED, correct)' || echo '(ALLOWED -- cap did not bite)')"
	else
		echo "  B: a pacman-paired transaction did NOT mark the accounting inconsistent this time"
	fi
done
