#!/usr/bin/env bash
# Add the [omarchy] repository, upgrade the system, and install install/packages.
#
# The package list is a flat file, not derived from prose, and every name in it
# must resolve with `pacman -Si` before a single package is installed — a name
# that resolves nowhere otherwise fails partway through a root transaction on a
# fresh machine.
#
# The bulk install runs with the mkinitcpio hook masked; see
# prepare_pacman_generation_override in lib/helpers.sh for why, and
# 13-bootloader.sh for the authoritative generation that follows it.

log "Updating system and installing required packages..."

PACMAN_CONF=${PACMAN_CONF:-/etc/pacman.conf}
PACMAN_ORIGINAL_BACKUP=${PACMAN_ORIGINAL_BACKUP:-$PACMAN_CONF.bunny-original}
PACMAN_ORIGINAL_CHECKSUM=${PACMAN_ORIGINAL_CHECKSUM:-$PACMAN_ORIGINAL_BACKUP.sha256}
PACMAN_REPOSITORY_FRAGMENT=${PACMAN_REPOSITORY_FRAGMENT:-/etc/pacman.d/bunny-repositories.conf}
REPOSITORY_FRAGMENT_SOURCE="$BUNNY_DEFAULTS/pacman/repositories.conf"

if [[ ! -f $BUNNY_INSTALL/packages ]]; then
	error "Package list not found: $BUNNY_INSTALL/packages"
	return 1
fi
if [[ ! -f $REPOSITORY_FRAGMENT_SOURCE ]]; then
	error "Repository fragment not found: $REPOSITORY_FRAGMENT_SOURCE"
	return 1
fi

declare -a required_packages=()
mapfile -t required_packages < <(grep -Ev '^(#|[[:space:]]*$)' "$BUNNY_INSTALL/packages")
if ((${#required_packages[@]} == 0)); then
	error "Package list is empty: $BUNNY_INSTALL/packages"
	return 1
fi

# Keep one pristine copy of the distribution's pacman.conf, and prove on every
# later run that it is still the copy we took — otherwise "restore the original"
# quietly means "restore whatever we last wrote over it".
preserve_original_pacman_configuration() {
	local saved_hash current_hash

	if [[ -e $PACMAN_ORIGINAL_BACKUP || -e $PACMAN_ORIGINAL_CHECKSUM ]]; then
		if [[ ! -f $PACMAN_ORIGINAL_BACKUP || ! -f $PACMAN_ORIGINAL_CHECKSUM ]]; then
			error "Pacman recovery files are incomplete"
			return 1
		fi
		saved_hash=$(sudo cat "$PACMAN_ORIGINAL_CHECKSUM" | tr -d '[:space:]')
		current_hash=$(sudo sha256sum "$PACMAN_ORIGINAL_BACKUP" | awk '{print $1}')
		if [[ -z $saved_hash || $saved_hash != "$current_hash" ]]; then
			error "Pacman configuration backup checksum does not match"
			return 1
		fi
		success "Original pacman configuration backup is intact"
		return 0
	fi

	run_logged "Preserving original pacman configuration" \
		sudo cp --preserve=mode,timestamps "$PACMAN_CONF" "$PACMAN_ORIGINAL_BACKUP"
	saved_hash=$(sudo sha256sum "$PACMAN_ORIGINAL_BACKUP" | awk '{print $1}')
	printf '%s\n' "$saved_hash" | sudo tee "$PACMAN_ORIGINAL_CHECKSUM" >/dev/null
	success "Original pacman configuration saved: $PACMAN_ORIGINAL_BACKUP"
}

# Rewrite pacman.conf so [omarchy] is defined in exactly one place — our included
# fragment. Any inline [omarchy] block is stripped first, so running this twice,
# or over a machine that had one added by hand, converges instead of stacking.
write_managed_pacman_configuration() {
	local staged_conf

	staged_conf=$(mktemp)
	awk -v managed_fragment="$PACMAN_REPOSITORY_FRAGMENT" '
      function emit(line) {
        while (pending_blanks > 0) { print ""; pending_blanks-- }
        print line
      }
      BEGIN { skip_omarchy = 0; pending_blanks = 0 }
      /^[[:space:]]*#[[:space:]]*BunnE-managed third-party repositories[[:space:]]*$/ { next }
      $0 ~ "^[[:space:]]*Include[[:space:]]*=[[:space:]]*" managed_fragment "[[:space:]]*$" { next }
      /^[[:space:]]*\[omarchy\][[:space:]]*$/ { skip_omarchy = 1; next }
      skip_omarchy && /^[[:space:]]*\[[^]]+\][[:space:]]*$/ { skip_omarchy = 0 }
      skip_omarchy { next }
      /^[[:space:]]*$/ { pending_blanks++; next }
      { emit($0) }
      END {
        print ""
        print "# BunnE-managed third-party repositories"
        print "Include = " managed_fragment
      }
    ' "$PACMAN_CONF" >"$staged_conf"

	sudo install -Dm644 "$REPOSITORY_FRAGMENT_SOURCE" "$PACMAN_REPOSITORY_FRAGMENT"

	# Parse the candidate before it becomes the live file: a pacman.conf pacman
	# cannot read leaves the machine unable to install the fix.
	if ! pacman-conf --config="$staged_conf" --repo-list >/dev/null; then
		rm -f "$staged_conf"
		error "Staged pacman configuration is invalid"
		return 1
	fi

	run_logged "Installing managed pacman configuration" \
		sudo cp "$staged_conf" "$PACMAN_CONF"
	rm -f "$staged_conf"
}

validate_pacman_configuration() {
	local repository count repositories policy

	repositories=$(pacman-conf --repo-list) || {
		error "Unable to read effective pacman configuration"
		return 1
	}

	for repository in core extra omarchy; do
		count=$(grep -cx "$repository" <<<"$repositories" || true)
		if ((count != 1)); then
			error "Repository must be configured exactly once: $repository (found $count)"
			return 1
		fi
	done

	if [[ $(pacman-conf --repo omarchy Server) != "https://pkgs.omarchy.org/stable/$(uname -m)" ]]; then
		error "Omarchy repository server does not match the managed configuration"
		return 1
	fi

	local omarchy_siglevel
	omarchy_siglevel=$(pacman-conf --repo omarchy SigLevel)
	for policy in PackageOptional PackageTrustAll DatabaseOptional DatabaseTrustAll; do
		if ! grep -qx "$policy" <<<"$omarchy_siglevel"; then
			error "Omarchy repository signature policy is missing: $policy"
			return 1
		fi
	done

	success "Pacman repositories and signature policy validated"
}

preserve_original_pacman_configuration
write_managed_pacman_configuration
validate_pacman_configuration

# Sync first so [omarchy] packages resolve, and check every name before the
# upgrade rather than discovering a typo after it.
run_logged "Synchronizing package databases" sudo pacman -Sy --noconfirm
validate_package_resolution "${required_packages[@]}"

# The full upgrade runs with normal hooks, so if it pulls a new kernel the boot
# artifacts are regenerated by the configuration that is currently known to work.
# Only the install that follows defers generation.
run_logged "Updating system with normal pacman hooks" sudo pacman -Syu --noconfirm

export BUNNY_PACMAN_HOOK_DIR=${BUNNY_PACMAN_HOOK_DIR:-/run/bunny-install/$BUNNY_UID/pacman-hooks}
prepare_pacman_generation_override
install_missing_packages "${required_packages[@]}"
