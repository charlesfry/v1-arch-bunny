#!/usr/bin/env bash
# Quiet the kernel/systemd console spam between LUKS unlock and the desktop
# painting. CHOICES.md `silent-boot`.
#
# Plymouth quits before niri has painted a frame — `plymouth-quit-wait.service`
# is ordered before `getty@tty1.service`, which starts well before niri is ready.
# That gap shows raw kernel/systemd text on a screen that was just a themed
# splash. This does not close the gap (`systemd-analyze` shows the firmware,
# loader, kernel and userspace phases are unaffected by console verbosity), it
# just stops the gap looking like a wall of boot log.
#
# `quiet loglevel=3 systemd.show_status=auto rd.udev.log_level=3` — the
# combination the Arch wiki's Silent boot article specifies. `quiet` and
# `loglevel=3` must both be present, and `quiet` must come first (kernel parameter
# parsing order); `systemd.show_status=auto` keeps failures visible, never `no`;
# `rd.udev.log_level=3` quiets udev's early-userspace chatter.
#
# Idempotent; honours BUNNY_DRY_RUN.
#
# Usage: 46-silent-boot.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}
root=${BUNNY_ROOT:?run me through install.sh, or set BUNNY_ROOT}

readonly WANT=(quiet 'loglevel=3' 'systemd.show_status=auto' 'rd.udev.log_level=3')
kcmd=/etc/kernel/cmdline

changed=false
for tok in "${WANT[@]}"; do
	if [[ -f $kcmd ]] && grep -qw -- "$tok" "$kcmd"; then
		say "  = $kcmd already has $tok"
		continue
	fi
	if [[ -n $dry ]]; then
		say "  ~ would add $tok to $kcmd"
		changed=true
		continue
	fi
	if [[ -f $kcmd ]]; then
		sudo sed -i "s/\$/ $tok/" "$kcmd"
	else
		sudo install -Dm644 /dev/stdin "$kcmd" <<<"$(cat /proc/cmdline) $tok"
	fi
	grep -qw -- "$tok" "$kcmd" || {
		say "  ! could not add $tok to $kcmd"
		exit 1
	}
	say "  + added $tok to $kcmd"
	changed=true
done

if [[ -n $dry ]]; then exit 0; fi

if $changed; then
	sudo mkinitcpio -P
	say "  ✓ initramfs rebuilt"
else
	say "  = nothing changed, initramfs not rebuilt"
fi

checker="$root/scripts/check-limine.sh"
if [[ -x $checker ]]; then
	sudo "$checker" >/dev/null || {
		say "  ! scripts/check-limine.sh rejected the regenerated limine.conf"
		exit 1
	}
	say "  ✓ check-limine.sh passes"
fi
for tok in "${WANT[@]}"; do
	grep -qw -- "$tok" "$kcmd" || {
		say "  ! $kcmd is missing $tok after the rebuild"
		exit 1
	}
done
say "  ✓ $kcmd has all four silent-boot parameters"
