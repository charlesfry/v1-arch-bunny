#!/usr/bin/env bash
# Boot straight into the desktop: getty autologin on tty1, and a login shell that
# execs the compositor. CHOICES.md `display-manager` (+ `disk-unlock`, `shell`).
#
# This is the whole display manager. greetd was installed, configured with the
# shape the decision was about (`initial_session` to niri, `agreety` on logout),
# driven for an evening, and removed: 6.8 MB PSS resident forever for a bare text
# login on a TTY, with boot time a wash (benchmarks/4.19, n=2/arm).
# getty-autologin costs 0 MB and no extra unit, because getty is running anyway.
# The security cost is real: anyone past the disk password is logged in as you.
#
# Two halves, and neither works alone. agetty logs the user in; the login shell
# starts niri. Splitting them is what keeps Ctrl-Alt-F2 a plain text console
# instead of a second compositor.
#
# The drop-in is one flag, because Arch's getty@.service already ships
# `ExecStart=-/usr/bin/agetty --noreset --noclear - ${TERM}`. The Arch wiki's
# widely-copied version instead writes
# `-/sbin/agetty -o "-p -f -- \u" --noclear --autologin USER %I $TERM`, which
# drops `--noreset`, hardcodes a path, and re-specifies by hand the `-f username`
# that `--autologin` already passes to login(1).
#
# The username is templated, never `bunny`: `$USER` is whoever is running the
# installer, and hardcoding the default would autologin an account that does not
# exist and leave the machine at a login prompt it never clears.
#
# ~/.bash_profile is appended to, not owned. `shell` is still `deferred` pending
# review, and writing the file wholesale would settle that by accident. The block
# is marked and matched on its own line.
#
# Idempotent; honours BUNNY_DRY_RUN.
#
# Usage: 60-autologin.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}

readonly DROPIN=/etc/systemd/system/getty@tty1.service.d/autologin.conf
readonly PROFILE=$HOME/.bash_profile

# Half one: agetty. The empty `ExecStart=` is required, not decorative: systemd
# appends to a list of ExecStart lines, so without the reset agetty would run
# twice.
#
# `${TERM}` and the leading `-` are systemd's and agetty's, not this shell's,
# hence a quoted heredoc with the username substituted afterwards.
dropin=$(
	sed "s|@USER@|$USER|" <<'EOF'
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --noreset --noclear --autologin @USER@ - ${TERM}
EOF
)

if [[ -f $DROPIN ]] && [[ $(sudo cat -- "$DROPIN") == "$dropin" ]]; then
	say "  = $DROPIN already autologs in $USER"
elif [[ -n $dry ]]; then
	say "  ~ would write $DROPIN (--autologin $USER)"
else
	sudo install -Dm644 /dev/stdin "$DROPIN" <<<"$dropin"
	sudo systemctl daemon-reload
	say "  + wrote $DROPIN"
fi

# Half two: the login shell. Guarded three ways: interactive only, so a `bash -c`
# from a script never execs a compositor; no WAYLAND_DISPLAY, so a terminal opened
# inside niri does not recurse; tty1 only, so the other VTs stay text consoles.
#
# `$(tty)` is one fork per interactive login shell — BUDGET.md's per-login bucket,
# so a few ms once a boot. The forkless alternatives are worse: bash has no tty
# builtin, and $XDG_VTNR is set by pam_systemd for a seat login but is empty over
# ssh, so testing it would make this depend on how the shell was reached.
read -r -d '' block <<'EOF' || true

# Bunny: autologin lands here on tty1 (CHOICES.md display-manager)
if [[ $- == *i* && -z $WAYLAND_DISPLAY && $(tty) == /dev/tty1 ]]; then
	exec niri-session
fi
EOF

# Matched on the `exec` line rather than the comment above it, and with leading
# whitespace allowed: a block a previous run appended and one somebody wrote by
# hand are both already-done.
if [[ -f $PROFILE ]] && grep -qE '^[[:space:]]*exec niri-session([[:space:]]|$)' "$PROFILE"; then
	say "  = $PROFILE execs niri-session"
elif [[ -n $dry ]]; then
	say "  ~ would append the niri-session block to $PROFILE"
else
	# A bash login shell reads .bash_profile OR .bash_login OR .profile — the
	# first that exists, and only that one. Creating .bash_profile on a machine
	# whose shell config lives in .profile would silently stop that file being
	# read at all.
	if [[ ! -e $PROFILE ]]; then
		# `if`, not `[[ ... ]] && say`: a false AND-list is a failed command under
		# `set -e`, and this one is on the normal path.
		for other in "$HOME/.bash_login" "$HOME/.profile"; do
			if [[ -e $other ]]; then
				say "  ! $other exists; creating $PROFILE means bash stops reading it"
			fi
		done
	fi
	printf '%s\n' "$block" >>"$PROFILE"
	say "  + appended the niri-session block to $PROFILE"
fi

if [[ -n $dry ]]; then exit 0; fi

# Prove the pieces exist. Both failures below look identical from the outside — a
# machine that sits at a text console after boot — and neither says why.
command -v niri-session >/dev/null || {
	say "  ! niri-session is not on PATH — autologin would land on a shell, not a desktop"
	exit 1
}

# getty@tty1 rather than getty@.service: the drop-in is instance-specific, and an
# `enabled` template with no enabled instance boots to nothing.
if [[ $(systemctl is-enabled getty@tty1.service 2>/dev/null || true) == enabled ]]; then
	say "  ✓ getty@tty1.service enabled"
else
	# Enabled by getty.target's generator on any normal machine, so its absence
	# means something took tty1 — historically greetd, whose
	# Conflicts=getty@tty1.service left exactly this trace.
	say "  ! getty@tty1.service is not enabled — something else owns tty1"
	if systemctl is-enabled greetd.service >/dev/null 2>&1; then
		say "    greetd is installed; display-manager rejected it 2026-08-25"
	fi
	exit 1
fi

# The effective value systemd will run, not the file this step just wrote: a
# second drop-in later in the directory wins, and this is the only check that
# would notice.
if systemctl show -p ExecStart --value getty@tty1.service | grep -q -- "--autologin $USER"; then
	say "  ✓ agetty will autologin $USER on tty1"
else
	say "  ! getty@tty1's effective ExecStart has no '--autologin $USER'"
	say "    another drop-in in /etc/systemd/system/getty@tty1.service.d/ overrides it"
	exit 1
fi
