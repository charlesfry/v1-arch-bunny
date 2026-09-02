#!/usr/bin/env bash
# Source the harvested shell helpers from .bashrc. CHOICES.md `shell-helpers`.
#
# Same shape and reasoning as 85-shell-prompt.sh: the file rides 70-dotfiles.sh's
# symlink walk, and all that is left is one `source` line appended to an
# otherwise-untracked ~/.bashrc. These are function definitions, so nothing runs
# until you type a name and nothing sits on the prompt path.
#
# Idempotent; honours BUNNY_DRY_RUN.
#
# Usage: 90-shell-helpers.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}

xdg_config=${XDG_CONFIG_HOME:-$HOME/.config}
src="$xdg_config/bash/helpers.bash"
rc="$HOME/.bashrc"

[[ -e $src ]] || {
	say "  ! $src not found -- run 70-dotfiles.sh first"
	exit 1
}

# shellcheck disable=SC2016 # deliberately unexpanded: this is what .bashrc should read at ITS runtime
line='. "${XDG_CONFIG_HOME:-$HOME/.config}/bash/helpers.bash"'
if [[ -f $rc ]] && grep -qxF "$line" "$rc"; then
	say "  = $rc sources helpers.bash"
elif [[ -n $dry ]]; then
	say "  ~ would append the helpers.bash source line to $rc"
else
	{
		printf '\n# Bunny: git and disk-forensics helpers (CHOICES.md shell-helpers)\n'
		printf '%s\n' "$line"
	} >>"$rc"
	say "  + appended the helpers.bash source line to $rc"
fi

if [[ -n $dry ]]; then exit 0; fi

# Sourcing cleanly is not enough: a typo inside a function body is a syntax error
# at source time, but a missing function is not, so check the names are defined.
missing=$(bash -c "
	. '$src' || exit 1
	for f in _git_default_branch gu gur _hr diagnose diagnose_snapshots; do
		declare -F \"\$f\" >/dev/null || printf '%s ' \"\$f\"
	done
" 2>&1) || {
	say "  ! sourcing $src failed:"
	say "    $missing"
	exit 1
}
if [[ -n $missing ]]; then
	say "  ! $src sourced but did not define: $missing"
	exit 1
fi
say "  ✓ helpers.bash sources cleanly and defines all six helpers"
