# direnv, gated on a real `cd`. CHOICES.md `dir-aware-display`; measured in
# benchmarks/3.5.prompt-and-shell.md — stock `_direnv_hook` run every prompt costs
# 15.0 ms, gated to fire only on directory change, 0.23 ms.
#
# `direnv hook bash` defines `_direnv_hook`, which is direnv's own gate: it
# decides whether the current directory's .envrc state changed since the last
# call. That is a real check rather than a rebuild, but it still runs every time
# it is called, so calling it every prompt (as its own docs suggest) pays that
# cost on every Enter.
#
# The eval has a side effect worth knowing about: that output does not just define
# `_direnv_hook`, it also prepends the ungated call into PROMPT_COMMAND itself. So
# evaling it and then appending our own gate leaves both installed, and the
# expensive ungated one still fires every prompt, silently defeating the point.
# Save and restore PROMPT_COMMAND around the eval so only the function definition
# survives.
_bunny_saved_pc=$PROMPT_COMMAND
eval "$(direnv hook bash)"
PROMPT_COMMAND=$_bunny_saved_pc
unset _bunny_saved_pc

_bunny_direnv() {
	[[ $PWD == "${_BUNNY_DIRENV_LASTPWD-}" ]] && return
	_BUNNY_DIRENV_LASTPWD=$PWD
	_direnv_hook
}

PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }_bunny_direnv"
