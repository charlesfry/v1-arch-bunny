#!/usr/bin/env bash
# Seed the wallpaper symlink scripts/bunny-wallpaper.sh and niri's own startup
# line both read. CHOICES.md `wallpaper`.
#
# The script and config need no step — 70-dotfiles.sh has them. What is left is
# the one thing that cannot be a tracked file: the symlink itself, which is
# user-mutable state (the whole point of the picker script), so this creates it
# only if missing and never touches it again. Same scaffold-never-own shape as
# 86-shell-dir-aware.sh's dirmap.conf.
#
# Idempotent; honours BUNNY_DRY_RUN.
#
# Usage: 87-wallpaper.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}
root=${BUNNY_ROOT:?run me through install.sh, or set BUNNY_ROOT}

default_wallpaper="$root/assets/wallpaper/2880x1920/15-neon-hare-by-omar-ramadan.jpg"
link="${XDG_CONFIG_HOME:-$HOME/.config}/bunny/wallpaper"

[[ -f $default_wallpaper ]] || {
	say "  ! $default_wallpaper not found"
	exit 1
}

if [[ -e $link || -L $link ]]; then
	say "  = $link already exists — left alone"
elif [[ -n $dry ]]; then
	say "  ~ would symlink $link -> $default_wallpaper"
else
	mkdir -p -- "$(dirname -- "$link")"
	ln -s "$default_wallpaper" "$link"
	say "  + symlinked $link -> $default_wallpaper"
fi

if [[ -n $dry ]]; then exit 0; fi

# Verify.
[[ -L $link ]] || {
	say "  ! $link exists but isn't a symlink"
	exit 1
}
[[ -e $link ]] || {
	say "  ! $link is a dangling symlink"
	exit 1
}
say "  ✓ wallpaper symlink resolves to $(readlink -f "$link")"
