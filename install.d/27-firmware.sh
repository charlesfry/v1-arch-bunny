#!/usr/bin/env bash
# Remove the firmware the `initramfs` row exists to keep out. CHOICES.md
# `initramfs` and `firmware-set`. Boot images drop from ~130 MB to ~25 MB each,
# and /boot from 590 MB used to 379 MB — which matters twice, since /boot is 1 GiB
# and also holds a kernel per bootable snapshot.
#
# Needed at all because archinstall installs the metapackage regardless of the
# ledger: `__packages__ = ['base', 'sudo', 'linux-firmware', 'mkinitcpio']` is
# hardcoded at lib/installer.py:69 and pacstrapped unconditionally, with no JSON
# key that prevents it.
#
# The mechanism behind the 104 MB: mkinitcpio's `kms` hook runs
# `add_checked_modules '/drivers/gpu/drm/'`, an NVIDIA card matches `nouveau`, and
# `add_module`'s firmware branch packs nouveau's entire declared firmware set —
# 661 files, Maxwell through Blackwell — into the uncompressed early CPIO.
# Blacklisting `nouveau` stops it loading, not being packed, and `MODULES=` has no
# exclusion syntax.
#
# `pacman -R`, never `-Rs`: `-Rs` would sweep every other `linux-firmware-*` split
# with it, wifi included, and a machine that cannot reach the network mid-install
# is a priority-1 failure. Both names are given together because the metapackage
# requires the nvidia split, so removing either alone fails.
#
# On an AMD machine the trap never fires — no NVIDIA card means `nouveau` is never
# autodetected — so it is a no-op there. It runs anyway: firmware for an absent
# GPU is not worth keeping either, and a step that behaves the same everywhere is
# one fewer conditional.
#
# Idempotent: does nothing when neither package is installed, which is the normal
# state after the first run. Honours BUNNY_DRY_RUN.
#
# Usage: 27-firmware.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}

readonly UNWANTED=(linux-firmware linux-firmware-nvidia)

present=()
for p in "${UNWANTED[@]}"; do
	pacman -Qq "$p" >/dev/null 2>&1 && present+=("$p")
done

if ((${#present[@]} == 0)); then
	say "  = neither linux-firmware nor linux-firmware-nvidia is installed"
elif [[ -n $dry ]]; then
	say "  ~ would remove: ${present[*]}"
	exit 0
else
	# `-R`, not `-Rs`: see the header.
	sudo pacman -R --noconfirm "${present[@]}"
	say "  + removed: ${present[*]}"
fi

if [[ -n $dry ]]; then exit 0; fi

# Verify both directions. The removal is only correct if the named splits survived
# it — `-Rs` instead of `-R`, or a split that was never marked explicit, both look
# like success and leave a machine with no wifi firmware at the next boot.
for p in "${UNWANTED[@]}"; do
	if pacman -Qq "$p" >/dev/null 2>&1; then
		say "  ! $p is still installed"
		exit 1
	fi
done

choices="${BUNNY_ROOT:?run me through install.sh, or set BUNNY_ROOT}/CHOICES.md"
mapfile -t splits < <(
	awk -F' *[|] *' '$5=="picked" && $4!="—" && $2 !~ "/" {print $4}' "$choices" |
		tr ' ' '\n' | grep '^linux-firmware-' | sort -u
)
((${#splits[@]} > 0)) || {
	say "  ! no linux-firmware-* splits found in CHOICES.md — the table format changed"
	exit 1
}
missing=()
for p in "${splits[@]}"; do
	pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p")
done
if ((${#missing[@]} > 0)); then
	say "  ! the removal took named splits with it: ${missing[*]}"
	say "    Reinstall them now — a machine with no wifi firmware cannot fetch them later."
	exit 1
fi
say "  ✓ metapackage gone, all ${#splits[@]} named splits intact"
