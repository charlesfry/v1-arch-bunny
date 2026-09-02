#!/usr/bin/env bash
# Add Windows to the Limine menu on a coexist install. CHOICES.md `bootloader` /
# `install-artifact` — desktop only, silent no-op on the Framework.
#
# Not a hand-edit of limine.conf. `limine-entry-tool` is already on the machine
# (`kernel-boot-entries`'s `limine-mkinitcpio-hook` package Provides it — same
# binary, no new packages) and is upstream's own supported mechanism for exactly
# this; Omarchy's dual-boot docs point at the same tool. Its non-interactive form
# is scriptable: `--add-efi ... --overwrite --quiet`. Same publisher as
# `limine-snapper-sync`, so no new trust surface, and entries it writes go through
# the same tree-aware parser rather than a hand-appended text block.
#
# Detection, not a flag: this installer runs unmodified on a Windows-coexist
# desktop and a Windows-less Framework 13, so it checks whether Windows' own EFI
# loader exists on the ESP.
#
# Unproven: whether an entry this tool writes survives `limine-snapper-sync`
# regenerating the menu on the next snapshot. Upstream's README says both tools do
# scoped inserts at a `//Snapshots` marker rather than whole-file regeneration, but
# the canary is still needed — add the entry, force a snapshot, confirm it is
# still there.
#
# Idempotent; honours BUNNY_DRY_RUN.
#
# Usage: 51-windows-chainload.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}

# ESP is mounted at /boot on every machine this installer targets (CHOICES.md
# `bootloader`) — root-only (fmask=0077,dmask=0077), hence sudo.
winloader=/boot/EFI/Microsoft/Boot/bootmgfw.efi
if ! sudo test -f "$winloader"; then
	# Expected absence on the Framework: one quiet line stating the reason, not a
	# failure.
	say "  i no Windows EFI loader found at $winloader -- nothing to add"
	exit 0
fi

finder="${BUNNY_ROOT:-}/scripts/find-limine-conf.sh"
[[ -x $finder ]] || {
	say "  ! scripts/find-limine-conf.sh not found at $finder"
	exit 1
}
LCONF=$(sudo "$finder") || {
	say "  ! could not locate limine.conf -- is limine installed?"
	exit 1
}
readonly LCONF

if sudo grep -qxF '/Windows' "$LCONF"; then
	say "  = Windows entry already in $LCONF"
elif [[ -n $dry ]]; then
	say "  ~ would add a Windows entry to $LCONF via limine-entry-tool --add-efi"
else
	sudo limine-entry-tool --add-efi "Windows" "$winloader" --overwrite --quiet
	sudo grep -qxF '/Windows' "$LCONF" || {
		say "  ! limine-entry-tool ran but no /Windows entry appeared in $LCONF"
		exit 1
	}
	say "  + added Windows entry to $LCONF"
fi

if [[ -n $dry ]]; then exit 0; fi

# Same validator 50-limine.sh uses — one place knows what a broken limine.conf
# looks like. Not optional and not a warning: this repo ships that script, so its
# absence means a broken checkout, and carrying on would mean having just
# rewritten the boot configuration with nothing confirming the machine can boot.
checker="${BUNNY_ROOT:-}/scripts/check-limine.sh"
[[ -x $checker ]] || {
	say "  ! scripts/check-limine.sh not found at $checker"
	say "    The boot config was just modified and cannot be validated."
	say "    Restore the checkout before rebooting."
	exit 1
}
sudo "$checker" "$LCONF" >/dev/null || {
	say "  ! scripts/check-limine.sh rejected $LCONF after adding Windows — run it directly for detail"
	exit 1
}
say "  ✓ check-limine.sh passes"
