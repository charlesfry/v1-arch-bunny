#!/usr/bin/env bash
# User-level session: the graphical-session services, GTK appearance, the
# wallpaper the compositor follows, and the AUR packages.
#
# Every daemon the desktop needs is a systemd user unit rather than a
# `spawn-at-startup` line in the niri config, so each one gets Restart=on-failure
# and proper ordering against graphical-session.target. niri's config is left with
# a single startup line, `uwsm finalize`.

# Each unit names an absolute binary. A unit whose ExecStart does not exist
# enables cleanly, starts at login, fails, and says nothing where anyone looks —
# which is exactly how the predecessor's polkit agent was dead for months.
verify_unit_binaries() {
	local unit binary missing=0
	local unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

	for unit in "$@"; do
		# Units that ship with their package are the package's problem, not ours.
		[[ -f $unit_dir/$unit.service ]] || continue
		binary=$(sed -n 's|^ExecStart=\(/[^ ]*\).*|\1|p' "$unit_dir/$unit.service" | head -1)
		[[ -n $binary ]] || continue
		if [[ ! -x $binary ]]; then
			error "$unit.service points at $binary, which does not exist"
			missing=1
		fi
	done
	if ((missing)); then
		error "Refusing to enable units that cannot start"
		return 1
	fi
	success "Every unit's ExecStart binary exists"
}

readonly USER_SERVICES=(waybar mako swaybg swayidle swayosd cliphist polkit-agent)

verify_unit_binaries "${USER_SERVICES[@]}"

for service in "${USER_SERVICES[@]}"; do
	if systemctl --user is-enabled --quiet "$service.service" 2>/dev/null; then
		info "$service.service already enabled"
	else
		run_logged "Enabling $service.service" systemctl --user enable "$service.service"
	fi
done

# The wallpaper swaybg.service follows is a symlink, not a file, so bunny-wallpaper
# can switch it live and a fresh boot picks up whatever it currently targets. That
# makes it user-mutable state: seed it once, then never touch it again.
wallpaper_link="${XDG_CONFIG_HOME:-$HOME/.config}/bunny/wallpaper"
wallpaper_default="$BUNNY_ROOT/assets/wallpaper/1920x1080/15-neon-hare-by-omar-ramadan.jpg"
if [[ -L $wallpaper_link || -e $wallpaper_link ]]; then
	info "Wallpaper already set: $(readlink -f -- "$wallpaper_link" || true)"
elif [[ ! -f $wallpaper_default ]]; then
	error "Default wallpaper missing: $wallpaper_default"
	return 1
else
	mkdir -p -- "$(dirname -- "$wallpaper_link")"
	ln -sfn -- "$wallpaper_default" "$wallpaper_link"
	success "Seeded wallpaper -> $(basename -- "$wallpaper_default")"
fi

log "Configuring GTK appearance"
if gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null &&
	gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark 2>/dev/null; then
	success "GTK set to Adwaita-dark"
else
	# Expected when the installer runs somewhere without a session bus; the
	# settings are per-user and can be re-applied by re-running this phase.
	warn "gsettings unavailable (no session bus) — GTK appearance not set"
fi

# The AUR, last, and deliberately after 13-bootloader.sh: yay shells out to pacman
# without --hookdir, so anything built here regenerates boot artifacts normally
# rather than under the deferral 10-packages.sh sets up.
aur_list="$BUNNY_INSTALL/packages-aur"
if [[ -f $aur_list ]]; then
	declare -a aur_packages=()
	mapfile -t aur_packages < <(grep -Ev '^(#|[[:space:]]*$)' "$aur_list")
	if ((${#aur_packages[@]} > 0)); then
		if ! command_exists yay; then
			error "yay not found — 10-packages.sh installs it from [omarchy]"
			return 1
		fi
		run_logged "Installing AUR packages: ${aur_packages[*]}" \
			yay -S --needed --noconfirm --aur "${aur_packages[@]}"
		for package in "${aur_packages[@]}"; do
			if ! package_installed "$package"; then
				error "AUR package failed to install: $package"
				return 1
			fi
		done
		success "AUR packages installed"
	fi
fi

verify_user_ownership \
	"${XDG_CONFIG_HOME:-$HOME/.config}" \
	"$HOME/.local"

success "User session configured"
