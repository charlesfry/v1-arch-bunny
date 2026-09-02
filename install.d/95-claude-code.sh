#!/usr/bin/env bash
# Put `claude` on PATH. CHOICES.md `agent-clis`, 02-functionality.md C7.
#
# Two halves, and the first is the one that bites. Claude Code installs into
# ~/.local/bin, and Arch does not put that directory on PATH — its /etc/profile
# calls `append_path` for /usr/local/bin and stops there. Without the export the
# installer succeeds and the command is still not found. So the export lands
# first, in .bash_profile rather than .bashrc: PATH is login-shell state, and
# re-prepending it on every interactive shell would grow the variable inside
# nested shells.
#
# The second half runs a remote script. `claude` is in no pacman repo we trust for
# it: Arch does not carry it, and while [omarchy] has a `claude-code` package that
# is a third party's rebuild of a tool that ships its own updater — a signed
# package fighting a self-updating binary for the same file. The upstream
# installer is the supported path, so what is trusted here is Anthropic over TLS,
# stated plainly. It is not piped into a shell blind: the script is downloaded,
# its shebang checked, and only then executed, so a captive-portal page or a
# truncated download fails as a file rather than as half a script that already
# ran. `--dry-run` downloads nothing.
#
# `claude` self-updates after this, which is why there is no version pin and no
# re-install on later runs.
#
# Idempotent; honours BUNNY_DRY_RUN.
#
# Usage: 95-claude-code.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}

readonly URL=https://claude.ai/install.sh
readonly PROFILE=$HOME/.bash_profile
readonly BIN=$HOME/.local/bin

# Half one: PATH.
# shellcheck disable=SC2016 # deliberately unexpanded: .bash_profile expands it at ITS runtime
line='[[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || PATH="$HOME/.local/bin:$PATH"'
if [[ -f $PROFILE ]] && grep -qxF "$line" "$PROFILE"; then
	say "  = $PROFILE puts ~/.local/bin on PATH"
elif [[ -n $dry ]]; then
	say "  ~ would append the ~/.local/bin PATH line to $PROFILE"
else
	{
		printf '\n# Bunny: ~/.local/bin is where Claude Code installs; Arch does not add it\n'
		printf '%s\n' "$line"
	} >>"$PROFILE"
	say "  + appended the ~/.local/bin PATH line to $PROFILE"
fi

# Half two: the binary.
if [[ -x $BIN/claude ]]; then
	say "  = claude already installed at $BIN/claude"
elif [[ -n $dry ]]; then
	say "  ~ would download $URL and run it to install claude into $BIN"
	exit 0
else
	tmp=$(mktemp)
	# shellcheck disable=SC2064 # $tmp is fixed now, and that is what should be removed
	trap "rm -f -- '$tmp'" EXIT
	curl -fsSL --proto '=https' --tlsv1.2 -o "$tmp" -- "$URL" || {
		say "  ! could not download $URL"
		exit 1
	}
	# A captive portal or an error page returns 200 with HTML in it. `curl -f`
	# does not catch that; reading the first line does.
	if [[ $(head -n1 -- "$tmp") != '#!'* ]]; then
		say "  ! $URL did not return a script -- refusing to run it"
		exit 1
	fi
	bash -- "$tmp" || {
		say "  ! the Claude Code installer failed"
		exit 1
	}
	say "  + installed claude into $BIN"
fi

if [[ -n $dry ]]; then exit 0; fi

# The installer is upstream's and its install location is upstream's choice, so
# check the binary is where the PATH line above actually points.
[[ -x $BIN/claude ]] || {
	say "  ! the installer ran but $BIN/claude is not there"
	exit 1
}
ver=$("$BIN/claude" --version 2>&1) || {
	say "  ! $BIN/claude is not runnable"
	exit 1
}
say "  ✓ $ver"
say "  i 'claude' needs one interactive login -- run it once to authenticate"
