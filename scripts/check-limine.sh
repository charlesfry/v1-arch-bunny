#!/usr/bin/env bash
# Find the limine.conf mistakes nothing else will catch. limine ships no validator
# at all, and on 2026-08-25 a structurally correct restructure of
# /boot/limine.conf took bunne-test off the network: making the OS entry a
# directory (the shape limine-snapper-sync needs) is only half the change, because
# `default_entry` defaults to 1, entry 1 is then the folder, and a folder does not
# boot. Nothing about that config was invalid — it parsed, `limine-list` rendered
# the tree correctly, and the only symptom was silence. benchmarks/4.24 has the
# account.
#
# The model below is read from limine's source, not CONFIG.md, which does not
# describe it (common/menu.c, v12.5.2 — the version in `extra`):
#
#   * `if (max_entries == 0 || selected_menu_entry->sub != NULL) skip_timeout = true;`
#     A directory as the selected entry forces the timeout off. The menu then
#     waits for input forever; it does not eventually boot something else.
#   * At the `autoboot:` label, a directory only toggles `expanded` and redraws —
#     Enter on a folder never boots.
#   * `print_tree()` counts an entry, then counts its children only if the
#     directory is `expanded`. So a numeric `default_entry` indexes the visible
#     tree: the `+` prefix that expands a directory is load-bearing.
#   * `find_entry_by_path()` — the non-numeric form — expands every directory
#     along the path and matches only where `sub == NULL`. A path-form default
#     cannot select a directory, and cannot be renumbered by a tool that reorders
#     entries. It is the robust spelling.
#
# Checks:
#   1. The default entry resolves, and resolves to something bootable.  (FAIL)
#   2. Every `boot():` file an entry boots from exists on the ESP.      (FAIL)
#
# Usage: scripts/check-limine.sh [limine.conf ...]   (default: found by find-limine-conf.sh)
#        ESP=/boot scripts/check-limine.sh some/other/limine.conf
#        scripts/check-limine.sh --self-test
set -Eeuo pipefail

# Emit one TSV row per entry: index<TAB>depth<TAB>dir<TAB>expanded<TAB>name, where
# index is the 1-based visible index limine's numeric default_entry uses.
entries() {
	awk '
		match($0, /^[[:space:]]*\/+\+?/) {
			title = substr($0, RSTART + RLENGTH)
			if (title == "") next
			marker = substr($0, RSTART, RLENGTH)
			n++
			depth[n] = gsub(/\//, "/", marker)
			expanded[n] = (substr($0, RSTART + RLENGTH - 1, 1) == "+") ? 1 : 0
			name[n] = title
		}
		END {
			# A directory is an entry the next one is deeper than.
			for (i = 1; i <= n; i++) dir[i] = (i < n && depth[i + 1] > depth[i])
			# Walk in file order. print_tree() counts an entry, then counts its
			# children only if the directory is expanded, so an entry under a collapsed
			# directory has no visible index and is emitted with index 0. Every entry is
			# still emitted: the path form of default_entry can reach the hidden ones.
			skip_below = 0
			idx = 0
			for (i = 1; i <= n; i++) {
				hidden = (skip_below && depth[i] > skip_below)
				if (!hidden) {
					skip_below = 0
					idx++
					if (dir[i] && !expanded[i]) skip_below = depth[i]
				}
				printf "%d\t%d\t%d\t%d\t%s\n", (hidden ? 0 : idx), depth[i], dir[i], expanded[i], name[i]
			}
		}
	' "$1"
}

# Print the path form of the first bootable entry, which is what `default_entry`
# should be set to. Same parser as the checks below, deliberately: a default the
# checker would reject is not worth writing. Walks back through shallower rows to
# build the ancestor chain, so it yields "Arch Linux (linux)" for a flat entry and
# "Arch Linux/linux" for a nested one.
default_path() {
	entries "$1" | awk -F'\t' '
		{ depth[NR] = $2; dir[NR] = $3; name[NR] = $5 }
		END {
			for (i = 1; i <= NR; i++) {
				if (dir[i]) continue
				path = name[i]; d = depth[i]
				for (j = i - 1; j >= 1; j--)
					if (depth[j] < d) { path = name[j] "/" path; d = depth[j] }
				print path
				exit
			}
		}'
}

check() {
	local cfg=$1 esp=${ESP:-/boot} fail=0 checked=()
	[ -r "$cfg" ] || {
		echo "cannot read $cfg" >&2
		return 1
	}

	local rows want
	rows=$(entries "$cfg")
	# Global option, may sit anywhere. Unset means 1 (CONFIG.md). Which of two
	# duplicates limine honours is undocumented and unread; last-wins is assumed
	# and stated here rather than left as a silent guess.
	want=$(sed -n 's/^[[:space:]]*default_entry:[[:space:]]*//p' "$cfg" | tail -1)
	: "${want:=1}"

	# Check 1: the default entry resolves to something bootable.
	if [[ $want =~ ^[0-9]+$ ]]; then
		local line
		line=$(printf '%s\n' "$rows" | awk -F'\t' -v i="$want" '$1 == i && i != 0')
		if [ -z "$line" ]; then
			echo "FAIL: $cfg — default_entry is $want, but the visible menu has only" \
				"$(printf '%s\n' "$rows" | awk -F'\t' '$1 != 0' | grep -c .) entries."
			echo "    Collapsed directories hide their children from the numbering, so a"
			echo "    '+' missing from an OS entry can put this index out of range."
			fail=1
		elif [ "$(cut -f3 <<<"$line")" = 1 ]; then
			local kid
			# Walk forward from the directory to its first bootable child. Not by
			# visible index: the children of a collapsed directory have none.
			kid=$(printf '%s\n' "$rows" | awk -F'\t' -v i="$want" '
				$1 == i && i != 0 { at = NR; d = $2; next }
				at && $2 <= d { exit }
				at && $3 == 0 { print $5; exit }')
			echo "FAIL: $cfg — default_entry $want is \"$(cut -f5 <<<"$line")\", a DIRECTORY."
			echo "    Limine forces the timeout off when the default is a folder and waits"
			echo "    at the menu forever (common/menu.c: selected_menu_entry->sub != NULL)."
			echo "    Prefer the path form, which cannot select a folder and cannot be"
			echo "    renumbered:   default_entry: $(cut -f5 <<<"$line")${kid:+/$kid}"
			fail=1
		fi
		checked+=("default_entry $want resolves to a bootable entry")
	else
		# Path form: expands directories along the way and matches only leaves, so
		# it cannot select a folder. Still worth resolving, since a typo leaves
		# default_entry silently pointing at nothing.
		local leaf=${want##*/}
		if printf '%s\n' "$rows" | awk -F'\t' -v n="$leaf" '$5 == n && $3 == 0 {found=1} END {exit !found}'; then
			checked+=("default_entry path \"$want\" ends at a bootable entry")
		else
			echo "FAIL: $cfg — default_entry \"$want\" names no bootable entry (looked for \"$leaf\")."
			echo "    A path-form default that resolves to nothing leaves entry 1 selected."
			fail=1
		fi
	fi

	# Check 2: booted files exist. Only `boot():` paths resolve to $esp. Other
	# resource forms (uuid(), guid(), hdd()) name a different volume; they are not
	# checked, and saying so is the point — a green line that quietly skipped half the
	# file is worse than none.
	local missing=0 n_checked=0 n_skipped p
	while read -r p; do
		[ -n "$p" ] || continue
		n_checked=$((n_checked + 1))
		[ -e "$esp/$p" ] || {
			echo "FAIL: $cfg — boots \"$p\", which does not exist under $esp"
			missing=1
		}
	done < <(sed -n 's/^[[:space:]]*\(module_\)\?path:[[:space:]]*boot():\///p' "$cfg" | cut -d'#' -f1)
	[ "$missing" = 0 ] || fail=1
	n_skipped=$(($(grep -cE '^[[:space:]]*(module_)?path:' "$cfg" || true) - n_checked))
	checked+=("$n_checked boot() file(s) present")
	[ "$n_skipped" -gt 0 ] && checked+=("$n_skipped path(s) NOT checked — not boot()-relative")

	# Advisory; never affects the exit code.
	printf '%s\n' "$rows" | awk -F'\t' '$3 == 1 && $4 == 0 {print "note: " $5 " is collapsed; its children are not in the numbering"}' |
		sed "s|^|$cfg: |"

	if [ "$fail" = 0 ]; then
		# Say what was checked, not "all good" — the point of check 2's skip count
		# is that it appears in the pass line, not only in a failure.
		local joined
		joined=$(printf '; %s' "${checked[@]}")
		echo "ok: $cfg — ${joined:2}"
	fi
	return "$fail"
}

# A check nobody runs is not a check. `--self-test` builds the config that took
# bunne-test off the network and asserts this script rejects it, plus the
# false-pass shapes an earlier version waved through.
self_test() {
	local d rc=0
	d=$(mktemp -d)
	trap 'rm -rf "$d"' RETURN
	mkdir -p "$d/esp/m/linux"
	: >"$d/esp/m/linux/vmlinuz"
	: >"$d/esp/m/linux/initramfs"
	cat >"$d/bad.conf" <<-'EOF'
		timeout: 1

		/Arch Linux
		comment: machine-id=m
		  //linux
		  protocol: linux
		  module_path: boot():/m/linux/initramfs#4a
		  path: boot():/m/linux/vmlinuz#93
	EOF
	# The robust repair: one path-form line, no '+' needed.
	sed 's|^timeout: 1|timeout: 1\ndefault_entry: Arch Linux/linux|' "$d/bad.conf" >"$d/good.conf"
	# The fragile repair, half-applied: an index a collapsed folder hides.
	sed 's|^timeout: 1|timeout: 1\ndefault_entry: 2|' "$d/bad.conf" >"$d/halfrepair.conf"
	# The fragile repair, fully applied.
	sed -e 's|^/Arch Linux|/+Arch Linux|' "$d/halfrepair.conf" >"$d/indexed.conf"
	# A default_entry path that names nothing.
	sed 's|^timeout: 1|timeout: 1\ndefault_entry: Totally/Nonexistent|' "$d/bad.conf" >"$d/badpath.conf"
	# A file the config boots that is not on the ESP.
	sed 's|/m/linux/vmlinuz|/m/linux/gone|' "$d/good.conf" >"$d/missing.conf"

	expect() { # expect <want-rc> <file> <description>
		local want=$1 f=$2 desc=$3 got=0
		ESP="$d/esp" check "$d/$f" >/dev/null 2>&1 || got=1
		[ "$got" = "$want" ] || {
			echo "SELF-TEST FAIL: $desc" >&2
			rc=1
		}
	}
	expect 1 bad.conf "a directory as default_entry was accepted"
	expect 1 halfrepair.conf "default_entry 2 behind a COLLAPSED directory was accepted (index is out of range)"
	expect 1 badpath.conf "a default_entry path naming nothing was accepted"
	expect 1 missing.conf "a missing boot file was accepted"
	expect 0 good.conf "the path-form repair was rejected"
	expect 0 indexed.conf "the index+expand repair was rejected"

	[ "$rc" = 0 ] && echo "self-test ok: rejects the 2026-08-25 config and three near-misses, accepts both repairs"
	return "$rc"
}

case "${1-}" in
--default-path)
	shift
	[[ -n ${1-} ]] || {
		printf 'usage: %s --default-path <limine.conf>\n' "$0" >&2
		exit 2
	}
	default_path "$1"
	exit
	;;
--self-test)
	self_test
	exit
	;;
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

# No args: find the live config rather than assume /boot/limine.conf — see
# find-limine-conf.sh for why that path isn't fixed. Falls back to the old guess
# if the finder is missing or comes up empty.
if (($# == 0)); then
	finder="$(dirname -- "$0")/find-limine-conf.sh"
	lconf=/boot/limine.conf
	[[ -x $finder ]] && lconf=$("$finder" 2>/dev/null || echo /boot/limine.conf)
	set -- "$lconf"
fi

fail=0
for cfg in "$@"; do check "$cfg" || fail=1; done
exit "$fail"
