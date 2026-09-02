#!/usr/bin/env bash
# greetd: autologin straight into niri, with a bare shell as the fallback session.
#
# The fallback is the point. If the compositor fails to start you land on
# /bin/sh and can fix it; without one, a broken niri config is a machine you
# cannot log into.
#
# uwsm owns the session, so niri's own user unit is disabled — the two of them
# both trying to manage the session is a fight neither wins.

log "Configuring greetd for direct autologin"

run_logged "Create /etc/greetd" sudo mkdir -p /etc/greetd

sudo tee /etc/greetd/config.toml >/dev/null <<TOML
[terminal]
vt = "next"

[general]
source_profile = true

[initial_session]
command = "uwsm start -- niri.desktop"
user = "$BUNNY_USER"

[default_session]
command = "/bin/sh"
user = "$BUNNY_USER"
TOML
success "Wrote /etc/greetd/config.toml"

if systemctl --user is-enabled niri.service >/dev/null 2>&1; then
	run_logged "Disable the niri.service user unit" \
		systemctl --user disable niri.service
else
	info "niri.service user unit is already disabled"
fi

# The predecessor arrangement, if this is an upgrade rather than a fresh install:
# agetty autologin on tty1 plus `exec niri-session` from .bash_profile. Left in
# place alongside greetd it fights for the VT.
readonly AUTOLOGIN_DROPIN=/etc/systemd/system/getty@tty1.service.d/autologin.conf
if [[ -f $AUTOLOGIN_DROPIN ]]; then
	run_logged "Removing the superseded getty autologin drop-in" \
		sudo rm -f "$AUTOLOGIN_DROPIN"
	sudo systemctl daemon-reload
fi

success "greetd configured — autologin user: $BUNNY_USER"
