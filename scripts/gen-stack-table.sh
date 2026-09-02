#!/usr/bin/env bash
# Generate README.md's Stack table from CHOICES.md.
#
# Generated rather than written because the table answers "what is in the build,
# and what is still undecided", which is what the ledger already records. A
# hand-written copy would be a second answer to the same question, and it would be
# wrong within a week. Same reasoning as install.d/20-packages.sh deriving its
# package list.
#
# The three states map onto ledger status directly:
#
#   picked, with packages     the package name(s)
#   picked, packages `—`      N/A — decided, and nothing gets installed for it
#   deferred                  TBD — not decided yet
#   only rejected rows        N/A — the decision was to install nothing
#
# A slot with several rows (a bake-off) collapses to its winner, because a stack
# table wants what is on the machine, not the history of how it got chosen. The
# Choice cell keeps the ledger's own link, so every row leads to its reasoning.
#
# Writes between the markers in README.md with --write, otherwise to stdout.
#
# Usage: scripts/gen-stack-table.sh [--write] [CHOICES.md]
set -Eeuo pipefail

write=false
case "${1-}" in
--write)
	write=true
	shift
	;;
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
choices=${1:-$here/../CHOICES.md}
readme=$here/../README.md
[[ -r $choices ]] || {
	echo "cannot read $choices" >&2
	exit 1
}

# Slots that are decisions about building Bunny rather than things on the finished
# machine. Listed explicitly rather than guessed at: a new process row shows up in
# the table until someone adds it here, which is visible, where a clever heuristic
# would drop a real component silently.
readonly SKIP='^(base-install-method|install-artifact|install-disk-mode|installer-prompts|install-profile|desktop-migration|dotfile-deployment|config-validation|benchmark-unlock)$'

gen() {
	awk -v skip="$SKIP" '
	BEGIN { FS = " *[|] *" }

	# Ledger rows only: | slot | pick | packages | status | date |
	NF >= 6 && $5 ~ /^(picked|deferred|rejected)$/ {
		slot = $2
		if (slot ~ skip) next
		rank = ($5 == "picked") ? 3 : ($5 == "deferred") ? 2 : 1
		if (!(slot in seen)) { order[++n] = slot; seen[slot] = 1 }
		if (!(slot in bestrank) || rank > bestrank[slot]) {
			bestrank[slot] = rank; pick[slot] = $3; pkgs[slot] = $4; status[slot] = $5
		}
	}

	# `pkg1 pkg2` -> `` `pkg1` `pkg2` ``, so a long cell still wraps readably.
	function code(list,   i, out, parts, k) {
		k = split(list, parts, " ")
		for (i = 1; i <= k; i++) out = out (i > 1 ? " " : "") "`" parts[i] "`"
		return out
	}

	END {
		print "| Slot | Choice | Packages |"
		print "|---|---|---|"
		for (i = 1; i <= n; i++) {
			s = order[i]
			# The ledger links to its own anchors; retarget them at CHOICES.md so
			# every row still leads to the reasoning and the measurements.
			choice = pick[s]
			gsub(/\]\(#/, "](CHOICES.md#", choice)
			if (status[s] == "deferred") {
				choice = "**TBD**"; p = "**TBD**"
			} else if (status[s] == "rejected") {
				choice = "N/A — decided against installing anything here"; p = "N/A"
			} else if (pkgs[s] == "—") {
				p = "N/A"
			} else {
				p = code(pkgs[s])
			}
			printf "| `%s` | %s | %s |\n", s, choice, p
			cnt[status[s]]++
		}
		printf "\n%d slots — %d picked, %d still TBD, %d resolved to nothing. ",
			n, cnt["picked"], cnt["deferred"], cnt["rejected"]
		printf "Generated from `CHOICES.md` by `scripts/gen-stack-table.sh`.\n"
	}
	' "$choices"
}

if ! $write; then
	gen
	exit
fi

if ! grep -q '^<!-- STACK:BEGIN -->$' "$readme" ||
	! grep -q '^<!-- STACK:END -->$' "$readme"; then
	echo "README.md has no STACK:BEGIN/STACK:END markers" >&2
	exit 1
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
{
	sed -n '1,/^<!-- STACK:BEGIN -->$/p' "$readme"
	gen
	sed -n '/^<!-- STACK:END -->$/,$p' "$readme"
} >"$tmp"
mv "$tmp" "$readme"
echo "README.md stack table regenerated" >&2
