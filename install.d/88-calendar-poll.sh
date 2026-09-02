#!/usr/bin/env bash
# Enable the calendar-poll user timer. CHOICES.md `notifications`.
#
# The files themselves need no step — same reasoning as 80-disk-alert.sh:
# `calendar-poll{,.service,.timer}` live under config/systemd/user/, already
# symlinked into place by 70-dotfiles.sh. What is left is enabling the timer.
#
# gcalcli auth is not this step's job. `gcalcli init` is an interactive OAuth flow
# that cannot run headlessly, and `secrets-bootstrap` already decided every secret
# here is copied in by hand. So the timer is enabled unconditionally (a poll with
# no auth is a cheap no-op) and this only warns once if auth has not been done —
# expected absence on a fresh install, not a failure.
#
# Usage: 88-calendar-poll.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

exit 0

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}

dest=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/calendar-poll.timer
[[ -e $dest ]] || {
	say "  ! $dest not found -- run 70-dotfiles.sh first"
	exit 1
}

if [[ $(systemctl --user is-enabled calendar-poll.timer 2>/dev/null || true) == enabled ]]; then
	say "  = calendar-poll.timer enabled"
elif [[ -n $dry ]]; then
	say "  ~ would enable calendar-poll.timer"
	exit 0
else
	systemctl --user daemon-reload
	systemctl --user enable --now calendar-poll.timer
	say "  + enabled calendar-poll.timer"
fi

if [[ -n $dry ]]; then exit 0; fi

# A unit can be "enabled" (a symlink in wants/) while the manager never actually
# scheduled it.
if systemctl --user list-timers calendar-poll.timer --no-legend 2>/dev/null | grep -q calendar-poll; then
	say "  ✓ calendar-poll.timer scheduled"
else
	say "  ! calendar-poll.timer is enabled but not in the timer list"
	say "    check: systemctl --user status calendar-poll.timer"
	exit 1
fi

oauth=${XDG_DATA_HOME:-$HOME/.local/share}/gcalcli/oauth
[[ -f $oauth ]] || say "  i gcalcli not yet authenticated -- run 'gcalcli init' once to enable meeting alerts"
