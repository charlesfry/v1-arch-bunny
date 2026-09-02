# Bash login shell.
#
# Bash reads .bash_profile OR .bash_login OR .profile — the first that exists,
# and only that one. Since this file exists, .profile has to be sourced by hand
# or the environment greetd also reads would be missing from every login shell.
#
# Nothing here starts a compositor. greetd's initial_session does that
# (install/12-greetd.sh); the getty-autologin arrangement this repo used before
# execed niri from here, and doing both starts two of them.

[ -f ~/.profile ] && . ~/.profile
[ -f ~/.bashrc ] && . ~/.bashrc
