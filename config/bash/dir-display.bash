# Directory-aware terminal title. CHOICES.md `dir-aware-display`; prototype and
# measurements in benchmarks/4.20.dir-aware-display.md.
#
# Reads a small user-editable mapping file (path-prefix -> short label) and sets
# the terminal's OSC-2 title to "[label] ~/short/path" when a prefix matches, or
# just the path when it does not. Fires only on a real `cd`, via a plain $PWD
# string compare — `prompt-hooks`'s rule, and the reason this measures 9.3 us per
# prompt on the hot path.
#
# The mapping file is not in this repo on purpose: it is exactly the kind of file
# that accumulates real employer and client directory names through normal use.
# install.d/86-shell-dir-aware.sh creates an empty template at
# $XDG_CONFIG_HOME/bunny/dirmap.conf the first time only.
#
# Per-directory tab colour is not wired up: CHOICES.md marks it optional (it would
# need kitty allow_remote_control plus a kitten fork per cd) and undecided. This
# ships the free half.

_bunny_dirmap_load() {
	_BUNNY_DIR_PREFIXES=() _BUNNY_DIR_LABELS=()
	local map=${XDG_CONFIG_HOME:-$HOME/.config}/bunny/dirmap.conf p n
	[[ -r $map ]] || return
	while IFS=$'\t' read -r p n; do
		[[ -z $p || $p == \#* ]] && continue
		_BUNNY_DIR_PREFIXES+=("$p")
		_BUNNY_DIR_LABELS+=("$n")
	done <"$map"
}

_bunny_dirhook() {
	[[ $PWD == "${_BUNNY_DIR_LASTPWD-}" ]] && return
	_BUNNY_DIR_LASTPWD=$PWD
	local i label=""
	for i in "${!_BUNNY_DIR_PREFIXES[@]}"; do
		if [[ $PWD == "${_BUNNY_DIR_PREFIXES[i]}" || $PWD == "${_BUNNY_DIR_PREFIXES[i]}"/* ]]; then
			label=${_BUNNY_DIR_LABELS[i]}
			break
		fi
	done
	if [[ -n $label ]]; then
		printf '\033]2;[%s] %s\007' "$label" "${PWD/#$HOME/\~}"
	else
		printf '\033]2;%s\007' "${PWD/#$HOME/\~}"
	fi
}

_bunny_dirmap_load
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }_bunny_dirhook"
