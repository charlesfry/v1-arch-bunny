#!/usr/bin/env bash
# Source the hand-rolled prompt from .bashrc. CHOICES.md `prompt` — 1.5 ms per
# prompt (12.5 ms with the dirty marker) against 35-43 ms for the off-the-shelf
# alternative.
#
# The file itself needs no step: config/bash/prompt.bash lives under
# $XDG_CONFIG_HOME and 70-dotfiles.sh symlinks it in. What is left is getting it
# sourced, which a symlink cannot do: bash has no XDG awareness, and ~/.bashrc is
# not tracked by this repo (`shell` is still `deferred`). So this appends one line
# rather than writing the file, same shape as 60-autologin.sh's .bash_profile
# block.
#
# Idempotent; honours BUNNY_DRY_RUN.
#
# Usage: 85-shell-prompt.sh [--help]
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
src="$xdg_config/bash/prompt.bash"
rc="$HOME/.bashrc"

[[ -e $src ]] || {
	say "  ! $src not found -- run 70-dotfiles.sh first"
	exit 1
}

# Matched on the `source` line itself: a line this step appended and one written
# by hand are both already-done.
# shellcheck disable=SC2016 # deliberately unexpanded: .bashrc expands it at ITS runtime
line='. "${XDG_CONFIG_HOME:-$HOME/.config}/bash/prompt.bash"'
if [[ -f $rc ]] && grep -qxF "$line" "$rc"; then
	say "  = $rc sources prompt.bash"
elif [[ -n $dry ]]; then
	say "  ~ would append the prompt.bash source line to $rc"
else
	{
		printf '\n# Bunny: hand-rolled prompt (CHOICES.md prompt)\n'
		printf '%s\n' "$line"
	} >>"$rc"
	say "  + appended the prompt.bash source line to $rc"
fi

if [[ -n $dry ]]; then exit 0; fi

# Source it in a non-interactive bash the way an interactive shell would, and
# check PS1 actually changed. PROMPT_COMMAND alone isn't proof — it could be set
# and still error out before touching PS1.
out=$(bash -c "PS1='unset'; . '$src'; _bunny_prompt; printf '%s' \"\$PS1\"" 2>&1) || {
	say "  ! sourcing $src failed:"
	say "    $out"
	exit 1
}
if [[ $out == "unset" || -z $out ]]; then
	say "  ! $src sourced without error but never set PS1"
	exit 1
fi
say "  ✓ prompt.bash sources cleanly and sets PS1"
