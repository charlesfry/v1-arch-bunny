#!/usr/bin/env bash
# The disk-usage alert timer.
#
# With no qgroup cap on the Docker subvolumes (60-docker.sh), this is not a
# warning light beside a hard limit -- it IS the protection against a full disk.
# Worth treating as such: a timer that is enabled but never scheduled is
# indistinguishable from one that is working, right up until the disk fills.

readonly ALERT_TIMER="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/disk-usage-alert.timer"

if [[ ! -e $ALERT_TIMER ]]; then
	error "$ALERT_TIMER not found — 20-dotfiles.sh links it"
	return 1
fi

if systemctl --user is-enabled --quiet disk-usage-alert.timer 2>/dev/null; then
	info "disk-usage-alert.timer already enabled"
else
	systemctl --user daemon-reload
	run_logged "Enabling disk-usage-alert.timer" \
		systemctl --user enable --now disk-usage-alert.timer
fi

# `is-enabled` only says a symlink exists. Ask systemd whether it is actually
# going to fire.
if systemctl --user list-timers disk-usage-alert.timer --no-legend 2>/dev/null | grep -q disk-usage-alert; then
	success "disk-usage-alert.timer scheduled"
else
	error "disk-usage-alert.timer is enabled but not scheduled"
	error "check: systemctl --user status disk-usage-alert.timer"
	return 1
fi
