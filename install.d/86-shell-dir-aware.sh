#!/usr/bin/env bash
# Source the directory-aware title and gated direnv hook from .bashrc, and
# scaffold the (untracked) mapping file. CHOICES.md `dir-aware-display`.
#
# The mechanism files need no step: config/bash/dir-display.bash and
# config/bash/direnv.bash are symlinked in by 70-dotfiles.sh. What is left is
# getting both sourced — same shape as 85-shell-prompt.sh, .bashrc stays untracked
# and one line is appended per file — and creating the mapping file once.
#
# The mapping file is scaffolded, never owned. It is deliberately not part of
# config/ (see dir-display.bash's own header): it is exactly the kind of file that
# accumulates real employer and client paths. So this writes an empty template
# only if the file does not exist, and never touches it again — overwriting it
# would be indistinguishable from destroying someone's customization.
#
# Both hooks are wired to run on directory change rather than on every prompt:
# 9.3 us for the title, and direnv gated this way costs 0.23 ms against 15 ms
# ungated.
#
# Idempotent; honours BUNNY_DRY_RUN.
#
# Usage: 86-shell-dir-aware.sh [--help]
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
rc="$HOME/.bashrc"

# 1. Source both mechanism files.
append_source() { # <relative-path-under-config/bash>
	local rel=$1
	local src="$xdg_config/bash/$rel"
	[[ -e $src ]] || {
		say "  ! $src not found -- run 70-dotfiles.sh first"
		exit 1
	}
	# shellcheck disable=SC2016 # deliberately unexpanded: this is what .bashrc should read at ITS runtime
	local line=". \"\${XDG_CONFIG_HOME:-\$HOME/.config}/bash/$rel\""
	if [[ -f $rc ]] && grep -qxF "$line" "$rc"; then
		say "  = $rc sources $rel"
	elif [[ -n $dry ]]; then
		say "  ~ would append the $rel source line to $rc"
	else
		{
			printf '\n# Bunny: %s (CHOICES.md dir-aware-display)\n' "$rel"
			printf '%s\n' "$line"
		} >>"$rc"
		say "  + appended the $rel source line to $rc"
	fi
}
append_source dir-display.bash
append_source direnv.bash

# 2. Scaffold the mapping file, once.
map="$xdg_config/bunny/dirmap.conf"
if [[ -e $map ]]; then
	say "  = $map already exists — left alone"
elif [[ -n $dry ]]; then
	say "  ~ would create an empty $map"
else
	read -r -d '' template <<'EOF' || true
# Directory-aware terminal title. CHOICES.md dir-aware-display.
# One prefix-then-label pair per line, separated by a tab. Empty by default --
# nothing ships here, since this repo never carries employer/client paths.
# Example (uncomment and edit; the label appears in the terminal title):
#/home/YOU/some-project	work
EOF
	mkdir -p -- "$(dirname -- "$map")"
	printf '%s\n' "$template" >"$map"
	say "  + created empty $map"
fi

if [[ -n $dry ]]; then exit 0; fi

# Both files run in the same shell, so an ordering bug (one clobbering the other's
# PROMPT_COMMAND) shows up here rather than only in isolation.
out=$(bash -c "
	. '$xdg_config/bash/dir-display.bash'
	. '$xdg_config/bash/direnv.bash'
	_bunny_dirhook; _bunny_direnv
	printf '%s' \"\$PROMPT_COMMAND\"
" 2>&1) || {
	say "  ! sourcing dir-display.bash + direnv.bash failed:"
	say "    $out"
	exit 1
}
if [[ $out != *_bunny_dirhook* || $out != *_bunny_direnv* ]]; then
	say "  ! PROMPT_COMMAND is missing a hook after sourcing both files: $out"
	exit 1
fi
say "  ✓ dir-display.bash + direnv.bash source cleanly and both hooks are wired"
