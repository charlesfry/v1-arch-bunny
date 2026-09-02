#!/usr/bin/env bash
# Pick a colour off the screen; put its hex on the clipboard. Bound to
# Mod+Shift+Print in config/niri/config.kdl.
#
# `-depth 8` is load bearing: without it `%[hex:...]` reports ImageMagick's
# internal 16-bit-per-channel value — "D3D37272F9F9" rather than "D372F9" — which
# is a valid hex colour string that no other tool here understands.
#
# Escape or right-click cancels the pick; slurp exits non-zero and so do we,
# without a notification, because a cancelled pick is not a failure.
#
# Usage: colorpick.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

coords=$(slurp -p) || exit 0

hex=$(grim -g "$coords" -t ppm - | magick - -depth 8 -format '#%[hex:p{0,0}]' info:-)

printf '%s' "$hex" | wl-copy
notify-send "Colour picked" "$hex"

# Data to stdout, so the script composes: `bg=$(colorpick.sh)`.
printf '%s\n' "$hex"
