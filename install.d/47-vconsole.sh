#!/usr/bin/env bash
# Stop `systemd-vconsole-setup.service` racing the console handover. CHOICES.md
# `silent-boot`.
#
# The failure: on roughly half of boots the unit ends up `failed`, with `loadkeys`
# reporting `Input/output error`. Nothing here installed it — the unit and the udev
# rule that fires it are systemd's own, and /etc/vconsole.conf is written by
# archinstall from the keyboard-layout question. The rule restarts the unit
# whenever a `vtcon*` device appears, and on this machine one appears during the
# plymouth -> autologin -> niri handover, at the moment tty1 is being taken into
# graphics mode. Timing decides it, which is why the same config passes one boot
# and fails the next.
#
# The fix is upstream's own option. vconsole.conf(5): "As a special case, if
# "@kernel" is specified, no keymap will be loaded, i.e. the kernel's default
# keymap will be used." No `loadkeys` call means nothing left to race. Masking the
# unit was the other candidate and is rejected: it would hide the whole mechanism,
# including from someone who does need a keymap.
#
# Only applied when the layout is already `us`, which is the entire guard. The
# kernel's built-in keymap is US QWERTY, so for a `us` machine this trades kbd's
# `us.map` for the compiled-in one — they differ only in AltGr, Ctrl-combo, keypad
# and F13-F20 slots, and only on a text console this machine reaches as a recovery
# path. For any other layout the setting is left alone: silently reverting a German
# keyboard to QWERTY to quiet a log line is a worse trade than the log line.
#
# Idempotent; honours BUNNY_DRY_RUN.
#
# Usage: 47-vconsole.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}

readonly CONF=/etc/vconsole.conf

# No file at all means no KEYMAP, and vconsole.conf(5) defaults KEYMAP to `us`
# when unset — so the race is still live and there is nothing to edit safely. A
# machine installed from this repo's JSON always has this file (`locale_config` is
# set in both, and installer.py writes `KEYMAP=<kb_layout>` unconditionally), so
# its absence means the machine was installed some other way.
[[ -f $CONF ]] || {
	say "  ! $CONF does not exist"
	say "    This repo's archinstall config always writes it (locale_config)."
	say "    Without it systemd still defaults KEYMAP to us and still calls"
	say "    loadkeys, so the boot race this step fixes would remain."
	exit 1
}

keymap=$(awk -F= '$1=="KEYMAP"{print $2; exit}' "$CONF")

case "$keymap" in
'@kernel')
	say "  = KEYMAP=@kernel already set"
	;;
us)
	if [[ -n $dry ]]; then
		say "  ~ would set KEYMAP=@kernel in $CONF (currently us)"
		exit 0
	fi
	sudo sed -i 's/^KEYMAP=us$/KEYMAP=@kernel/' "$CONF"
	say "  + KEYMAP=us -> @kernel in $CONF"
	;;
'')
	# Same reasoning as the missing file above: the JSON guarantees a KEYMAP line,
	# and an absent one leaves the race in place while looking like success.
	say "  ! $CONF exists but sets no KEYMAP"
	say "    systemd defaults it to us and still calls loadkeys, so the boot race"
	say "    this step fixes would remain. Add KEYMAP=us or KEYMAP=@kernel."
	exit 1
	;;
*)
	say "  = KEYMAP=$keymap left alone -- @kernel would silently revert it to US QWERTY"
	exit 0
	;;
esac

if [[ -n $dry ]]; then exit 0; fi

# Read back what is on disk, and prove systemd accepts the value rather than
# trusting that the man page and this build agree.
now=$(awk -F= '$1=="KEYMAP"{print $2; exit}' "$CONF")
[[ $now == '@kernel' ]] || {
	say "  ! $CONF still reads KEYMAP=$now after the edit"
	exit 1
}
sudo systemctl restart systemd-vconsole-setup.service || {
	say "  ! systemd-vconsole-setup rejected KEYMAP=@kernel"
	exit 1
}
say "  ✓ KEYMAP=@kernel, and systemd-vconsole-setup starts clean with it"
