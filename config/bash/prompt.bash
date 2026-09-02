# The prompt. CHOICES.md `prompt`; measurements in
# benchmarks/3.5.prompt-and-shell.md. Sourced from .bashrc by
# install.d/85-shell-prompt.sh — bash has no XDG awareness, so nothing finds this
# file on its own.
#
# 65.7 ms (starship) -> 1.5 ms (branch only) / 8.2-12.5 ms with the dirty marker,
# which the author took anyway. The rule that produced the win: no `$( )` anywhere
# on the prompt path except the one `git status` the dirty marker needs — a bare
# subshell alone measured 2.98 ms on a 226-variable environment, more than the
# rest of the prompt combined. Helpers assign to globals instead of echoing.
#
# Colours are plain ANSI rather than read from a palette file: `palette` is picked
# but has no templater yet, same as waybar/style.css.

_bunny_find_repo() { # -> _BR ; no subshell, no fork
	local d=$PWD
	_BR=
	while [[ $d == /?* ]]; do
		if [[ -e $d/.git ]]; then
			_BR=$d
			return
		fi
		d=${d%/*}
	done
	[[ -e /.git ]] && _BR=/
}

_bunny_read_branch() { # -> _BB ; one file read
	local h
	_BB=git
	[[ -r $_BR/.git/HEAD ]] || return
	read -r h <"$_BR/.git/HEAD" || return
	case $h in
	ref:*) _BB=${h##*/} ;;
	*) _BB=${h:0:7} ;;
	esac
}

_bunny_prompt() {
	local rc=$? dirty='' tail o
	_bunny_find_repo
	if [[ $_BR ]]; then
		_bunny_read_branch
		tail=${PWD#"$_BR"}
		# git status, not diff-index: measured faster, and catches untracked files,
		# which diff-index cannot see.
		o=$(git status --porcelain 2>/dev/null)
		[[ $o ]] && dirty=' ●'
		PS1="\[\e[1;36m\]${_BR##*/}${tail}\[\e[0m\] \[\e[3;36m\]${_BB}\[\e[0m\]\[\e[36m\]${dirty}\[\e[0m\] "
	else
		PS1='\[\e[1;36m\]\w\[\e[0m\] '
	fi
	if ((rc)); then
		PS1+=$'\[\e[1;36m\]✗\[\e[0m\] '
	else
		PS1+=$'\[\e[1;36m\]❯\[\e[0m\] '
	fi
}

PROMPT_COMMAND=_bunny_prompt
