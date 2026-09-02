#!/usr/bin/env bash
set -Eeuo pipefail

# Validates ASCII animation frame directories against the rules in BRIEF.md.
# Authoring tooling only — nothing here ships to a machine or runs at install
# time, so it is not the Phase 4 installer code CLAUDE.md defers.
#
#   ./check.sh <dir>...          validate
#   ./check.sh --show <dir>...   validate, then print every frame boxed

usage() {
	printf 'usage: %s [--show] <animation-dir>...\n' "${0##*/}" >&2
	exit 2
}

show=0
[[ ${1-} == --help ]] && usage
if [[ ${1-} == --show ]]; then
	show=1
	shift
fi
[[ $# -gt 0 ]] || usage

fail=0
err() {
	printf '%s\n' "$*" >&2
	fail=1
}

check_dir() {
	local dir=$1 f w h n=0
	local -a frames lines

	mapfile -t frames < <(find "$dir" -maxdepth 1 -type f -name '[0-9][0-9][0-9].txt' | sort)
	if [[ ${#frames[@]} -lt 2 ]]; then
		err "$dir: needs at least 2 frames, found ${#frames[@]}"
		return
	fi

	for f in "${frames[@]}"; do
		n=$((n + 1))
		# Numbering must be contiguous from 001 so a player can just count.
		[[ $(basename "$f") == "$(printf '%03d.txt' "$n")" ]] ||
			err "$f: out of sequence, expected $(printf '%03d.txt' "$n")"

		# Anything outside printable ASCII — tabs and CR included — breaks the
		# fixed-width guarantee the player depends on. Captured rather than
		# piped into a loop: a pipeline's subshell cannot set `fail`.
		local bad
		bad=$(LC_ALL=C grep -n '[^ -~]' "$f" | cut -d: -f1 | tr '\n' ' ' || true)
		[[ -z ${bad// /} ]] || err "$f: non-ASCII on line(s): $bad"

		[[ $(tail -c1 "$f" | wc -l) -eq 1 ]] || err "$f: no trailing newline"

		mapfile -t lines <"$f"
		if [[ $n -eq 1 ]]; then
			h=${#lines[@]}
			w=${#lines[0]}
		fi
		[[ ${#lines[@]} -eq $h ]] ||
			err "$f: height ${#lines[@]}, frame 001 is $h"
		for i in "${!lines[@]}"; do
			[[ ${#lines[i]} -eq $w ]] ||
				err "$f:$((i + 1)): width ${#lines[i]}, expected $w (pad with spaces)"
		done
	done

	printf '%s: %d frames, %dx%d\n' "$dir" "${#frames[@]}" "$w" "$h" >&2

	if [[ $show -eq 1 ]]; then
		for f in "${frames[@]}"; do
			printf -- '--- %s ---\n' "$f"
			awk -v w="$w" '{printf "|%-*s|\n", w, $0}' "$f"
		done
	fi
}

for d in "$@"; do
	[[ -d $d ]] || {
		err "$d: not a directory"
		continue
	}
	check_dir "$d"
done

exit "$fail"
