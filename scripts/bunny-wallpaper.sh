#!/usr/bin/env bash
# Pick a wallpaper from assets/wallpaper/ via fuzzel and make it the live and
# persistent desktop background. CHOICES.md `wallpaper` — one image, no
# per-monitor variety.
#
# niri's own startup line (config/niri/config.kdl) points swaybg at the fixed
# symlink $XDG_CONFIG_HOME/bunny/wallpaper rather than a hardcoded file, so
# switching is "repoint the symlink and respawn swaybg" and a fresh boot follows
# whatever it currently targets. install.d/87-wallpaper.sh seeds it once; this is
# the only thing that changes it after that.
#
# Usage: bunny-wallpaper.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

wallpaper_dir="${XDG_DATA_HOME:-$HOME/.local/share}/arch-bunny/assets/wallpaper/1920x1080"
link="${XDG_CONFIG_HOME:-$HOME/.config}/bunny/wallpaper"

[[ -d $wallpaper_dir ]] || {
	printf 'no such directory: %s\n' "$wallpaper_dir" >&2
	exit 1
}

choice=$(find "$wallpaper_dir" -maxdepth 1 -type f -printf '%f\n' | sort | fuzzel --dmenu)
[[ -n $choice ]] || exit 0 # cancelled

mkdir -p -- "$(dirname -- "$link")"
ln -sfn "$wallpaper_dir/$choice" "$link"

# Respawn so the change is visible immediately, not just at next login.
pkill -x swaybg || true
setsid swaybg -i "$link" -m fill -c "#0f0f0f" >/dev/null 2>&1 &
disown

printf 'wallpaper set to %s\n' "$choice" >&2
