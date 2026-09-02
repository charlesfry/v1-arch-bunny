#!/usr/bin/env bash
# Enable the disk-usage-alert user timer. CHOICES.md `disk-alert`.
#
# The files themselves need no step: `disk-usage-alert`,
# `disk-usage-alert.service` and `disk-usage-alert.timer` live under
# config/systemd/user/, which 70-dotfiles.sh already symlinks into
# $XDG_CONFIG_HOME. What is left is enabling the timer, which a symlink cannot do.
#
# One `df` is the whole design (see the script's own header). No root helper, no
# sudoers entry, no package.
#
# Usage: 80-disk-alert.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}

dest=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/disk-usage-alert.timer
[[ -e $dest ]] || {
	say "  ! $dest not found -- run 70-dotfiles.sh first"
	exit 1
}

if [[ $(systemctl --user is-enabled disk-usage-alert.timer 2>/dev/null || true) == enabled ]]; then
	say "  = disk-usage-alert.timer enabled"
elif [[ -n $dry ]]; then
	say "  ~ would enable disk-usage-alert.timer"
	exit 0
else
	systemctl --user daemon-reload
	systemctl --user enable --now disk-usage-alert.timer
	say "  + enabled disk-usage-alert.timer"
fi

if [[ -n $dry ]]; then exit 0; fi

# A unit can be "enabled" (a symlink in wants/) while the manager never actually
# scheduled it.
if systemctl --user list-timers disk-usage-alert.timer --no-legend 2>/dev/null | grep -q disk-usage-alert; then
	say "  ✓ disk-usage-alert.timer scheduled"
else
	say "  ! disk-usage-alert.timer is enabled but not in the timer list"
	say "    check: systemctl --user status disk-usage-alert.timer"
	exit 1
fi
