#!/usr/bin/env bash
# Crop the bunny wallpapers to the aspect ratios Bunny targets, keeping the bunny.
#
# The three target resolutions are only two aspect ratios — 1920x1080 and
# 3840x2160 are both 16:9, 2880x1920 is 3:2 — so each source needs one 16:9 crop
# and one 3:2 crop, and the 1080p asset is a downscale of the 4K one.
#
# Not `-gravity center`: the bunny is usually near a corner, so a centre crop
# decapitates it. The table below carries the bunny's centre as a fraction of the
# source, read off each image by eye. The crop is the largest rectangle of the
# target aspect that fits in the source, positioned on that point and clamped to
# the edges, so the bunny stays in frame and no upscaling happens.
#
# A source too small for a target is skipped, not upscaled, and says so.
#
# Usage: scripts/prep-wallpapers.sh [--dry-run] [--out DIR] [SRCDIR]
set -Eeuo pipefail

# source file|bunny centre x|bunny centre y   (output name is the file's stem).
# cx/cy are fractions of the source. 0.5/0.5 means "no rabbit found, centre it"
# (the artsy frames), which is the documented fallback.
readonly ROWS='
01-crimson-eye-by-buse-doga-ay.jpg|0.72|0.50
02-prism-side-of-the-moon.webp|0.50|0.50
03-clover-dreamer-by-enq-1998.jpg|0.50|0.45
04-flower-thief-by-gary-bendig.jpg|0.58|0.45
05-monochrome-watch-by-ierc.jpg|0.60|0.47
06-curious-lop-by-jadon-barnes.jpg|0.42|0.45
07-silver-repose-by-jei-lee.jpg|0.45|0.50
08-wireframe-wardens-by-klim-musalimov.jpg|0.50|0.48
09-polygon-shrine-by-li-lin.jpg|0.47|0.45
10-field-sentinel-by-lisa-siefert.jpg|0.50|0.62
11-close-quarters-by-nare-gevorgyan.jpg|0.38|0.42
12-tuxedo-profile-by-nikolett-emmert.jpg|0.62|0.52
13-harlequin-lop-by-nikolett-emmert.jpg|0.44|0.55
14-meadow-alert-by-nora-jane-long.jpg|0.54|0.44
15-neon-hare-by-omar-ramadan.jpg|0.62|0.53
16-botanist-unsplash-1577158669097.avif|0.55|0.47
17-carrot-heist-unsplash-1658441710879.avif|0.68|0.40
18-dusk-path-unsplash-1681545263363.avif|0.50|0.63
19-velvet-lop-unsplash-1717538854317.avif|0.58|0.50
20-midnight-graze-by-sina-bahar.jpg|0.48|0.60
21-tallgrass-by-steve-smith.jpg|0.65|0.36
22-ember-coat-by-irina.jpg|0.42|0.55
'

readonly TARGETS='1920x1080 3840x2160 2880x1920'

dry_run=false
out=''
src=''
while [ $# -gt 0 ]; do
	case "$1" in
	--dry-run) dry_run=true ;;
	--out) out="$2" && shift ;;
	-h | --help)
		sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
		exit 0
		;;
	*) src="$1" ;;
	esac
	shift
done
: "${src:=$(dirname "$0")/../assets/wallpaper}"
: "${out:=$src}"

command -v magick >/dev/null || {
	echo "need imagemagick (magick)" >&2
	exit 1
}

made=0 skipped=0
while IFS='|' read -r file cx cy; do
	[ -n "${file:-}" ] || continue
	name=${file%.*}
	[ -r "$src/$file" ] || {
		echo "missing: $file" >&2
		exit 1
	}
	read -r sw sh < <(magick identify -format '%w %h\n' "$src/${file}[0]")

	for target in $TARGETS; do
		tw=${target%x*} th=${target#*x}
		# Largest crop of the target aspect that fits inside the source. Integer
		# math: compare sw/sh against tw/th as sw*th vs tw*sh.
		if [ $((sw * th)) -ge $((tw * sh)) ]; then
			croph=$sh cropw=$((sh * tw / th))
		else
			cropw=$sw croph=$((sw * th / tw))
		fi
		if [ "$cropw" -lt "$tw" ]; then
			echo "skip  $name $target — source ${sw}x${sh} too small, would upscale" >&2
			skipped=$((skipped + 1))
			continue
		fi
		# Put the crop on the bunny, then clamp so it stays inside the source.
		x=$(awk -v c="$cx" -v s="$sw" -v w="$cropw" \
			'BEGIN{v=int(c*s-w/2); if(v<0)v=0; if(v>s-w)v=s-w; print v}')
		y=$(awk -v c="$cy" -v s="$sh" -v h="$croph" \
			'BEGIN{v=int(c*s-h/2); if(v<0)v=0; if(v>s-h)v=s-h; print v}')

		mkdir -p "$out/$target"
		if $dry_run; then
			echo "$name $target crop ${cropw}x${croph}+${x}+${y} from ${sw}x${sh}"
		else
			magick "$src/${file}[0]" -crop "${cropw}x${croph}+${x}+${y}" +repage \
				-resize "$target" -quality 92 "$out/$target/$name.jpg"
		fi
		made=$((made + 1))
	done
done <<<"$ROWS"

echo "$made written, $skipped skipped (too small)" >&2
