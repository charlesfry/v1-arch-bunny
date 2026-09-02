# Interactive bash.

[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# The shell pieces live under $XDG_CONFIG_HOME/bash. Bash has no XDG awareness,
# so this file is the only thing that knows where to find them. Sourced
# unguarded on purpose: install/20-dotfiles.sh links all four, so a missing one
# is a broken install and should say so rather than degrade to a bare prompt.
for _bunny_rc in prompt dir-display direnv helpers; do
	. "${XDG_CONFIG_HOME:-$HOME/.config}/bash/$_bunny_rc.bash"
done
unset _bunny_rc

# Machine-local additions: conda, per-employer settings, anything that must not
# live in a public repo. Untracked by design, and absent on a fresh install.
if [[ -f ~/.bashrc.personal ]]; then
	. ~/.bashrc.personal
fi
