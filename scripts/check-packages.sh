#!/usr/bin/env bash
# Check that every package CHOICES.md claims exists, and say which repo it is in.
# Every `Packages` cell is a claim that a package exists, and nothing else
# verifies it; 4.17 found one that never existed (`ttf-fragment-mono`), and a
# wrong name fails halfway through a root install on a fresh machine.
#
# The second half is the sequencing fact docs/05-choices.md records: the list is
# not installable in one command. Some packages come from the pinned [omarchy]
# repo and some from the AUR, so install.sh needs an order — official repos, then
# [omarchy], then bootstrap the AUR helper, then the AUR. This prints that
# grouping so the ordering is derived from the ledger rather than hardcoded.
#
# Run it on a machine that has the repos configured. Packages resolved by neither
# pacman nor the AUR are a failure, not a warning.
#
# Usage: scripts/check-packages.sh [CHOICES.md]
set -Eeuo pipefail

choices=${1:-$(dirname "$0")/../CHOICES.md}
[ -r "$choices" ] || {
	echo "cannot read $choices" >&2
	exit 1
}
command -v pacman >/dev/null || {
	echo "needs pacman (run this on the Arch box)" >&2
	exit 1
}

# docs/05-choices.md's parse, verbatim — the same one the installer uses.
mapfile -t pkgs < <(
	awk -F' *[|] *' '$5=="picked" && $4!="—" && $2 !~ "/" {print $4}' "$choices" |
		tr ' ' '\n' | grep -v '^$' | sort -u
)
[ "${#pkgs[@]}" -gt 0 ] || {
	echo "no picked packages parsed from $choices" >&2
	exit 1
}
echo "${#pkgs[@]} distinct packages claimed by picked rows" >&2

# One pacman call, not one per package. Missing names produce no record.
declare -A repo_of=()
while read -r field _ value; do
	case "$field" in
	Repository) r=$value ;;
	Name) repo_of["$value"]=$r ;;
	esac
done < <(pacman -Si "${pkgs[@]}" 2>/dev/null | grep -E '^(Repository|Name) ')

missing=()
for p in "${pkgs[@]}"; do
	[ -n "${repo_of[$p]:-}" ] || missing+=("$p")
done

# Anything pacman could not resolve is either AUR or a typo; only the AUR helper
# can tell them apart, and it needs the network.
aur=() unknown=()
if [ "${#missing[@]}" -gt 0 ] && command -v yay >/dev/null; then
	for p in "${missing[@]}"; do
		if yay -Si "$p" >/dev/null 2>&1; then aur+=("$p"); else unknown+=("$p"); fi
	done
else
	unknown=("${missing[@]}")
fi

# Report grouped by install order, which is the point.
for r in $(printf '%s\n' "${repo_of[@]}" | sort -u); do
	printf '\n[%s]\n' "$r"
	for p in "${pkgs[@]}"; do [ "${repo_of[$p]:-}" = "$r" ] && printf '  %s\n' "$p"; done
done
[ "${#aur[@]}" -eq 0 ] || printf '\n[aur]\n%s\n' "$(printf '  %s\n' "${aur[@]}")"

if [ "${#unknown[@]}" -gt 0 ]; then
	printf '\nFAIL: %d package(s) exist in no repo and no AUR:\n' "${#unknown[@]}" >&2
	printf '  %s\n' "${unknown[@]}" >&2
	echo "A wrong name here fails partway through a root install on a fresh machine." >&2
	exit 1
fi
echo >&2
echo "ok: all ${#pkgs[@]} packages resolve" >&2
