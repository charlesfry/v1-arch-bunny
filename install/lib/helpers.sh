#!/usr/bin/env bash
# Helper functions for installation.
# Provides logging, output formatting, and error handling.
#
# Sourced by install.sh before any phase runs. Phases are sourced too, so these
# are in scope everywhere; a phase reports failure with `return 1`, never `exit`.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Message from arguments, or from stdin when called with none. The heredoc form
# is what lets a caller log a multi-line block without quoting it.
_read_message() {
	if (($#)); then
		printf '%s' "$*"
	else
		cat
	fi
}

_log() {
	local level="$1"
	local color="$2"
	shift 2

	local message
	message="$(_read_message "$@")"

	if [[ -n $level ]]; then
		if [[ -n $color ]]; then
			printf '%b\n' "${color}${level}${NC} $message"
		else
			printf '%s %s\n' "$level" "$message"
		fi
	else
		printf '%s\n' "$message"
	fi

	printf '[%s] %s\n' "$(date '+%F %T')" "$message" >>"$BUNNY_LOG"
}

log() { _log "" "" "$@"; }
info() { _log "INFO" "$BLUE" "$@"; }
important() { _log "==>" "\033[1;34m" "$@"; }
success() { _log "✓" "$GREEN" "$@"; }
warn() { _log "WARNING" "$YELLOW" "$@"; }
error() { _log "ERROR" "$RED" "$@"; }

# Print section header.
# Usage: section "Display Manager Configuration"
section() {
	local title="$1"
	echo ""
	printf '%b\n' "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	printf '%b\n' "${BLUE}${NC} $title"
	printf '%b\n' "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	log "Starting: $title"
	echo ""
}

# Run a command, sending its output to both the terminal and the install log.
# Usage: run_logged "description" command arg1 arg2 ...
#
# The `tee` makes this a pipeline, so the exit status reported below is only the
# command's because install.sh sets `pipefail`.
run_logged() {
	local description="$1"
	shift
	local exit_code command_string

	printf -v command_string '%q ' "$@"
	log "$description"
	log "Command: ${command_string% }"

	if "$@" 2>&1 | tee -a "$BUNNY_LOG"; then
		success "$description completed"
		return 0
	else
		exit_code=$?
		error "$description failed with exit code $exit_code"
		return "$exit_code"
	fi
}

# Usage: command_exists pacman
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Usage: package_installed niri
package_installed() {
	pacman -Q "$1" >/dev/null 2>&1
}

# Fail if a path managed by the installer contains files owned by another user.
# The installer runs unprivileged but escalates per command, so a `sudo` that
# should not have been there shows up here as root-owned state under $HOME.
verify_user_ownership() {
	local path unexpected_owner

	for path in "$@"; do
		[[ -e $path ]] || continue
		unexpected_owner=$(find "$path" -xdev ! -uid "$BUNNY_UID" -print -quit)
		if [[ -n $unexpected_owner ]]; then
			error "Unexpected ownership under $path: $unexpected_owner"
			return 1
		fi
	done
}

# Confirm every configured package resolves from the synchronized repositories.
# A name that resolves nowhere fails partway through a root install otherwise.
validate_package_resolution() {
	local package
	local -a unresolved=()

	for package in "$@"; do
		if ! pacman -Si -- "$package" >/dev/null 2>&1; then
			unresolved+=("$package")
		fi
	done

	if ((${#unresolved[@]} > 0)); then
		error "Required packages do not resolve: ${unresolved[*]}"
		return 1
	fi
	success "All required packages resolve from configured repositories"
}

# Mask the mkinitcpio install hook for the bulk package transaction only.
#
# `90-mkinitcpio-install.hook` triggers on usr/lib/initcpio/*, usr/lib/firmware/*,
# usr/bin/cryptsetup, usr/lib/systemd/systemd and the mkinitcpio package itself, so
# a large install rebuilds the whole boot image several times over. Only the last
# build survives, and 13-bootloader.sh runs `limine-update` explicitly anyway.
#
# The override is a /dev/null symlink, which alpm-hooks(5) documents as the way to
# disable a hook, in a directory passed with `--hookdir` on that one command line.
# Nothing under /etc is touched and the directory lives on tmpfs, so an interrupted
# install cannot leave hooks disabled for later invocations of pacman.
prepare_pacman_generation_override() {
	local override_hook

	: "${BUNNY_PACMAN_HOOK_DIR:?BUNNY_PACMAN_HOOK_DIR is not set}"
	override_hook="$BUNNY_PACMAN_HOOK_DIR/90-mkinitcpio-install.hook"

	run_logged "Creating private pacman hook override" \
		sudo rm -rf -- "$BUNNY_PACMAN_HOOK_DIR"
	sudo install -d -m 700 "$BUNNY_PACMAN_HOOK_DIR"
	sudo ln -s /dev/null "$override_hook"

	if [[ $(sudo readlink "$override_hook") != /dev/null ]]; then
		error "Pacman generation hook override is invalid: $override_hook"
		return 1
	fi
	success "Package-triggered boot generation will be deferred after the system upgrade"
}

remove_pacman_generation_override() {
	: "${BUNNY_PACMAN_HOOK_DIR:?BUNNY_PACMAN_HOOK_DIR is not set}"
	run_logged "Removing private pacman hook override" \
		sudo rm -rf -- "$BUNNY_PACMAN_HOOK_DIR"
}

install_packages_without_generation() {
	local override_hook

	if (($# == 0)); then
		error "No packages supplied for installation"
		return 1
	fi

	: "${BUNNY_PACMAN_HOOK_DIR:?BUNNY_PACMAN_HOOK_DIR is not set}"
	override_hook="$BUNNY_PACMAN_HOOK_DIR/90-mkinitcpio-install.hook"
	if [[ $(sudo readlink "$override_hook" 2>/dev/null) != /dev/null ]]; then
		error "Pacman generation hook override is not active: $override_hook"
		return 1
	fi

	run_logged "Installing packages with boot generation deferred: $*" \
		sudo pacman --hookdir "$BUNNY_PACMAN_HOOK_DIR" \
		-S --noconfirm --needed "$@"
}

# Usage: install_missing_packages git neovim ripgrep
install_missing_packages() {
	local packages=("$@")
	local missing=()
	local pkg

	info "Checking ${#packages[@]} required packages..."

	for pkg in "${packages[@]}"; do
		if ! package_installed "$pkg"; then
			missing+=("$pkg")
		fi
	done

	if ((${#missing[@]} == 0)); then
		info "All required packages were already installed."
		success "Required packages are installed and verified"
		return 0
	fi

	info "Installing ${#missing[@]} missing package(s): ${missing[*]}"
	install_packages_without_generation "${missing[@]}"

	# `--needed` is silent about a package it skipped for the wrong reason, and a
	# partially-failed transaction still exits 0 in some pacman paths.
	info "Verifying installed packages..."
	local verify_failed=0
	for pkg in "${packages[@]}"; do
		if ! package_installed "$pkg"; then
			error "Failed to verify package: $pkg"
			verify_failed=1
		fi
	done
	if ((verify_failed)); then
		return 1
	fi
	success "Required packages are installed and verified"
}
