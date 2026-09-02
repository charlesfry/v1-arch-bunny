#!/usr/bin/env bash
# install.sh — turn a vanilla Arch install into BunnE.
#
# The base install (partitioning, LUKS2, btrfs, UKI, bootloader) is archinstall's
# job; see README.md. Everything here runs on a machine that already boots and has
# a user.
#
# This file only sequences. Each phase is a numbered script in install/, and
# `ls install/` is the plan. Phases are *sourced*, so they share the helpers and
# report failure with `return 1` rather than `exit`.
set -Eeuo pipefail

if ((EUID == 0)); then
	echo "Error: run install.sh as a normal user, not as root or through sudo." >&2
	exit 1
fi

BUNNY_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export BUNNY_ROOT
if [[ $PWD != "$BUNNY_ROOT" ]]; then
	echo "Error: install.sh must be run from the repository root ($BUNNY_ROOT)" >&2
	exit 1
fi

export BUNNY_INSTALL="$BUNNY_ROOT/install"
export BUNNY_DEFAULTS="$BUNNY_INSTALL/default"
export BUNNY_LOG="${BUNNY_LOG:-${XDG_STATE_HOME:-$HOME/.local/state}/bunny/install.log}"
export BUNNY_RUN_ID="${BUNNY_RUN_ID:-$(date '+%Y%m%dT%H%M%S')-$$}"
export BUNNY_TRACE="${BUNNY_TRACE:-$BUNNY_LOG.$BUNNY_RUN_ID.trace}"
export BUNNY_PHASE="startup"

# The full `set -x` trace goes to its own file, not the terminal. It records every
# command the installer ran as root, so it stays readable only by its owner.
mkdir -p "$(dirname "$BUNNY_LOG")"
touch "$BUNNY_LOG" "$BUNNY_TRACE"
chmod 600 "$BUNNY_TRACE"
exec 19>>"$BUNNY_TRACE"
export BASH_XTRACEFD=19
export PS4='+ ${BASH_SOURCE##*/}:${LINENO}: '
set -x

if [[ ! -f $BUNNY_INSTALL/lib/helpers.sh ]]; then
	echo "Error: helper functions not found at $BUNNY_INSTALL/lib/helpers.sh" >&2
	exit 1
fi
# shellcheck source=install/lib/helpers.sh
source "$BUNNY_INSTALL/lib/helpers.sh"

BUNNY_ERROR_REPORTED=0
_install_error() {
	local status=$1 line=$2 command=$3

	if ((BUNNY_ERROR_REPORTED == 0)); then
		BUNNY_ERROR_REPORTED=1
		error "Installation failed: run=$BUNNY_RUN_ID phase=$BUNNY_PHASE status=$status line=$line command=$command"
	fi
	return "$status"
}
trap '_install_error "$?" "$LINENO" "$BASH_COMMAND"' ERR

# 10-packages.sh masks the mkinitcpio hook for its bulk transaction and
# 13-bootloader.sh removes the mask once it has run the authoritative
# `limine-update`. If the run dies in between, packages are installed against boot
# artifacts nobody regenerated — the machine still boots on the old image, and
# then fails at some unrelated update weeks later. The override directory existing
# at exit is exactly that state, so rebuild before leaving.
_restore_boot_generation() {
	local status=$?

	[[ -n ${BUNNY_PACMAN_HOOK_DIR:-} && -d ${BUNNY_PACMAN_HOOK_DIR:-} ]] || return "$status"
	warn "Boot generation was still deferred at exit — regenerating before leaving"
	sudo rm -rf -- "$BUNNY_PACMAN_HOOK_DIR"
	if sudo limine-update; then
		success "Boot artifacts regenerated"
	else
		error "limine-update FAILED after an interrupted install."
		error "Do not reboot until 'sudo limine-update' succeeds."
	fi
	return "$status"
}
trap _restore_boot_generation EXIT

# Source a numbered install phase or fail.
run_phase() {
	local script="$BUNNY_INSTALL/$1"
	local title="${2:-$1}"

	export BUNNY_PHASE="$1"
	if [[ ! -f $script ]]; then
		error "Phase script not found: $script"
		exit 1
	fi
	section "$title"
	log "Phase context: run=$BUNNY_RUN_ID phase=$1 user=$(id -un) uid=$(id -u) pwd=$PWD"
	# shellcheck disable=SC1090 # numbered phase paths are validated immediately above
	source "$script"
	success "$title complete"
}

section "https://github.com/bunnrbbt/arch-bunny"
cat <<'EOF'
   (\_/)
   ( •_•)   B U N N E
  / >💾     arch, scrolled

EOF

info "Installing system from: $BUNNY_ROOT"
important "Logfile: $BUNNY_LOG"
log "Installation started at: $(date '+%Y-%m-%d %H:%M:%S')"

run_phase "00-preflight.sh" "Preflight checks"
# shellcheck disable=SC2034 # set and exported by 00-preflight.sh, read by later phases
readonly BUNNY_USER BUNNY_UID BUNNY_HOME

run_phase "10-packages.sh" "Packages and repositories"
run_phase "12-greetd.sh" "Display manager"
run_phase "13-bootloader.sh" "Bootloader and boot process"
run_phase "20-dotfiles.sh" "Dotfiles"
run_phase "30-system-services.sh" "System services"
run_phase "40-user-setup.sh" "User session"
run_phase "50-firewall.sh" "Firewall"

export BUNNY_PHASE="complete"
success "Installation completed"
log "Installation finished: run=$BUNNY_RUN_ID status=0"
info "Reboot to start the configured desktop session."
info "Installation log: $BUNNY_LOG"
