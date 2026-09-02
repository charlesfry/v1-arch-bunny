#!/usr/bin/env bash
# Find niri keybind collisions `niri validate` cannot see.
#
# niri's validator compares keybinds as literal strings, but "Mod" is a special
# modifier equal to Super on a TTY, so `Super+Ctrl+L` and `Mod+Ctrl+L` are the
# same chord at runtime and two different strings to the parser. On 2026-08-21 a
# proposed lock binding of Super+Ctrl+L validated clean while silently shadowing
# move-column-right-or-to-monitor-right.
#
# Usage: scripts/check-keybinds.sh [config.kdl ...]
set -Eeuo pipefail

# A keybind line is indented, its first token is a chord, and it carries an action
# in braces. KDL comments a node out with a leading "/-".
chords() {
	sed -e 's|//.*||' "$1" |
		grep -E '\{' |
		grep -vE '^[[:space:]]*/-' |
		awk '{print $1}' |
		grep -E '^[A-Za-z0-9_]+(\+[A-Za-z0-9_]+)+$' || true
}

# Super and Mod are one key; sort modifiers so ordering cannot hide a duplicate.
normalise() {
	awk -F'+' '{
		key = $NF
		n = 0
		for (i = 1; i < NF; i++) { m = ($i == "Super") ? "Mod" : $i; mods[++n] = m }
		for (i = 1; i < n; i++) for (j = i + 1; j <= n; j++)
			if (mods[i] > mods[j]) { t = mods[i]; mods[i] = mods[j]; mods[j] = t }
		out = ""
		for (i = 1; i <= n; i++) out = out mods[i] "+"
		print out key
		delete mods
	}'
}

check() {
	local cfg=$1 all norm dupes total super_lines
	[ -r "$cfg" ] || {
		echo "cannot read $cfg" >&2
		return 1
	}
	all=$(chords "$cfg")
	total=$(printf '%s\n' "$all" | grep -c . || true)
	norm=$(printf '%s\n' "$all" | normalise)
	dupes=$(printf '%s\n' "$norm" | sort | uniq -d | grep -c . >/dev/null && printf '%s\n' "$norm" | sort | uniq -d || true)

	if [ -n "$dupes" ]; then
		echo "FAIL: $cfg — chord bound more than once (Super and Mod are the same key):"
		while read -r d; do
			[ -n "$d" ] || continue
			echo "    $d"
			grep -nE "^[[:space:]]+(Mod|Super)[^[:space:]]*[[:space:]]" "$cfg" |
				awk -v want="$d" -F: '{line=$0; sub(/^[0-9]+:/,"",line); split(line,a," "); print $1": "a[1]}' |
				while read -r hit; do
					c=${hit#*: }
					n=$(printf '%s\n' "$c" | normalise)
					[ "$n" = "$d" ] && echo "        $hit"
				done
		done <<<"$dupes"
		return 1
	fi

	super_lines=$(grep -nE "^[[:space:]]+Super\+" "$cfg" || true)
	if [ -n "$super_lines" ] && grep -qE "^[[:space:]]+Mod\+" "$cfg"; then
		echo "WARN: $cfg mixes the two spellings of one key. Collisions become invisible:"
		printf '%s\n' "$super_lines" | sed 's/^/    /'
		echo "    ...alongside $(grep -cE '^[[:space:]]+Mod\+' "$cfg") Mod+ bindings. Pick one spelling."
	fi

	echo "ok: $cfg — $total chords, no duplicates"
}

fail=0
for cfg in "${@:-config/niri/config.kdl}"; do check "$cfg" || fail=1; done
exit "$fail"
