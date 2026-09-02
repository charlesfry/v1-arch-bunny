#!/usr/bin/env bash
# Refuse to start unless the machine is what every later phase assumes.
#
# Sourced by install.sh — `return 1` here aborts the run before anything has been
# written. Checking all of this up front is the same instinct as asking every
# installer question before the first destructive operation.

log "Validating required components..."

if ((EUID == 0)); then
	error "Run the installer as a normal user, not as root or through sudo"
	return 1
fi

# The user the installer will configure is whoever is running it, resolved from
# the passwd database rather than from the environment, because $HOME and $USER
# are trivially wrong under su and sudo -E.
BUNNY_UID=$(id -u)
BUNNY_USER=$(id -un)
passwd_entry=$(getent passwd "$BUNNY_UID")
if [[ -z $passwd_entry ]]; then
	error "No passwd entry found for uid $BUNNY_UID"
	return 1
fi
IFS=: read -r passwd_user _ passwd_uid _ _ passwd_home _ <<<"$passwd_entry"

if [[ $passwd_user != "$BUNNY_USER" || $passwd_uid != "$BUNNY_UID" ]]; then
	error "Current user does not match the passwd database entry"
	return 1
fi
if [[ $HOME != "$passwd_home" ]]; then
	error "HOME is $HOME, but the passwd database specifies $passwd_home"
	return 1
fi
if [[ ! -d $HOME || ! -w $HOME || ! -O $HOME ]]; then
	error "Home directory must exist, be writable, and be owned by $BUNNY_USER: $HOME"
	return 1
fi

expected_runtime_dir="/run/user/$BUNNY_UID"
if [[ ${XDG_RUNTIME_DIR:-} != "$expected_runtime_dir" ]]; then
	error "XDG_RUNTIME_DIR must be $expected_runtime_dir"
	return 1
fi
if [[ ! -d $XDG_RUNTIME_DIR || ! -w $XDG_RUNTIME_DIR || ! -O $XDG_RUNTIME_DIR ]]; then
	error "Runtime directory must exist, be writable, and be owned by $BUNNY_USER"
	return 1
fi

export BUNNY_UID BUNNY_USER
export BUNNY_HOME="$passwd_home"
success "User context confirmed: $BUNNY_USER ($BUNNY_UID)"

log "Checking that the system is x86_64..."
if [[ $(uname -m) == x86_64 ]]; then
	success "x86_64 CPU"
else
	error "Not an x86_64 CPU"
	return 1
fi

# Secure Boot would reject the unsigned Limine binary this repo installs.
log "Checking that Secure Boot is disabled..."
if bootctl status 2>/dev/null | grep -q 'Secure Boot: enabled'; then
	error "Secure boot needs to be disabled"
	return 1
fi
success "Secure Boot is disabled"

for tool in pacman systemctl limine btrfs cryptsetup; do
	log "Checking for $tool..."
	if command_exists "$tool"; then
		success "$tool found"
	else
		error "$tool not found — is this the Arch install README.md describes?"
		return 1
	fi
done

log "Checking that the user systemd manager is reachable..."
if systemctl --user show-environment >/dev/null 2>&1; then
	success "User systemd manager is reachable"
else
	error "User systemd manager is not reachable"
	return 1
fi

log "Checking for sudo access..."
if sudo -n true 2>/dev/null; then
	success "sudo access confirmed (no password required)"
elif sudo -v 2>/dev/null; then
	success "sudo access confirmed"
else
	error "No sudo access — required for system configuration"
	return 1
fi
