#!/usr/bin/env bash
# Locate the live limine.conf without assuming a path. archinstall's Limine setup
# writes /boot/EFI/arch-limine/limine.conf (`removable: false`, our setting) or
# /boot/EFI/BOOT/limine.conf (`removable: true`), while a manual install here left
# it flat at /boot/limine.conf. Hardcoding either guess breaks the other —
# CHOICES.md `bootloader`.
#
# The algorithm is limine's own, from /usr/share/doc/limine/CONFIG.md, "Location
# of the config file": first the directory holding the EFI app that was actually
# booted, then these four paths on the boot drive in order —
# /boot/limine/limine.conf, /boot/limine.conf, /limine/limine.conf,
# /limine.conf.
#
# No case-folding needed: vfat resolves lookups case-insensitively in the kernel
# even where `ls` shows a different on-disk case than efibootmgr reports.
#
# efibootmgr needs no root here (efivars are world-readable) and is used
# best-effort: if it is missing — this can run before the package step that
# installs it — discovery falls to the four-path scan, which is pure file tests.
#
# The ESP itself may not be readable. archinstall's fstab entry for /boot mounts
# vfat with `fmask=0077,dmask=0077`, so a non-root caller cannot tell "no
# limine.conf here" from "can't see in here at all". That case exits 2, distinct
# from exit 1's real not-found, so 00-preflight.sh (which must not need root) can
# say "can't check" instead of reporting a false failure.
#
# Prints the path on stdout if found and exits 0. Exits 1 with a reason on stderr
# if a real search found nothing. Exits 2 if the ESP needs root.
#
# Usage: find-limine-conf.sh [--help]
#        ESP=/boot find-limine-conf.sh
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

esp=${ESP:-/boot}

if [[ ! -r $esp || ! -x $esp ]]; then
	echo "$esp is not readable without root (archinstall's own default ESP mount" \
		"options, fmask=0077/dmask=0077, do this) -- re-run with root to search it" >&2
	exit 2
fi

# 1. Next to the EFI app that was actually booted.
if command -v efibootmgr >/dev/null; then
	id=$(efibootmgr 2>/dev/null | sed -n 's/^BootCurrent:[[:space:]]*//p')
	if [[ -n $id ]]; then
		# `|| true`: no match here is a normal fall-through to step 2 (the BootCurrent
		# entry can be gone from NVRAM), not an error. Without it, pipefail turns that
		# into a silent exit before the `-n $efi_path` check below runs.
		efi_path=$(efibootmgr -v 2>/dev/null | grep "^Boot${id}" | grep -ioE '\\[^[:space:]]*\.efi' | head -1) || true
		if [[ -n $efi_path ]]; then
			efi_dir=${efi_path%\\*}
			efi_dir=${efi_dir//\\//}
			candidate="$esp$efi_dir/limine.conf"
			if [[ -r $candidate ]]; then
				printf '%s\n' "$candidate"
				exit 0
			fi
		fi
	fi
fi

# 2. limine's own boot-drive scan, ESP-relative.
for candidate in "$esp/boot/limine/limine.conf" "$esp/boot/limine.conf" "$esp/limine/limine.conf" "$esp/limine.conf"; do
	if [[ -r $candidate ]]; then
		printf '%s\n' "$candidate"
		exit 0
	fi
done

echo "no limine.conf found under $esp -- checked the booted EFI app's directory and" \
	"all four of limine's own boot-drive candidates (see CONFIG.md)" >&2
exit 1
