#!/usr/bin/env bash
# install.sh — turn a vanilla Arch install into Bunny.
#
# The base install (partitioning, LUKS2, btrfs, bootloader) is archinstall's job;
# see CHOICES.md base-install-method. Everything here runs on a machine that
# already boots and has a user.
#
# This file only sequences. Each step is a standalone script in install.d/,
# numbered so `ls` is the plan. Steps are executed, not sourced. They are
# idempotent, which is also the resume story: fix the cause and re-run.
#
# Usage: ./install.sh [--dry-run] [--help]
#   --dry-run   every step reports what it would change and writes nothing
set -Eeuo pipefail

# Resolved from this file's own location, so the installer works from any
# working directory.
BUNNY_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly BUNNY_ROOT
readonly STEP_DIR="$BUNNY_ROOT/install.d"

# Note: `~` does not expand inside double quotes, hence $HOME.
BUNNY_LOG=${BUNNY_LOG:-${XDG_STATE_HOME:-$HOME/.local/state}/bunny/install.log}
readonly BUNNY_LOG

dry_run=false
while (($#)); do
	case "$1" in
	--dry-run)
		dry_run=true
		shift
		;;
	-h | --help)
		sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
		exit
		;;
	*)
		echo "unknown option: $1 (try --help)" >&2
		exit 1
		;;
	esac
done

# The two checks that must happen before anything is written. They run before the
# log directory exists and report to stderr only, so a refusal leaves no trace.
abort() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

command -v pacman >/dev/null ||
	abort "no pacman — this installs Bunny onto Arch Linux, not onto this system"

# Steps escalate per command, which keeps every use of root visible. Run as root,
# every file created under $HOME would be root-owned instead.
((EUID != 0)) ||
	abort "do not run this as root (or with sudo) — run it as your user; steps escalate per command"

mkdir -p -- "$(dirname -- "$BUNNY_LOG")"

# Informational output to stderr, timestamped copy to the log. Nothing is written
# to stdout at all.
say() {
	printf '%s\n' "$*" >&2
	printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$BUNNY_LOG"
}

die() {
	say "ERROR: $*"
	exit 1
}

# Which step is running, so the EXIT trap can name it.
current_step=
on_exit() {
	local rc=$?
	# Not `((rc == 0)) && return`: a false AND-list is itself a failed command under
	# `set -e`, so a real failure would exit here without printing why.
	if ((rc == 0)); then return; fi
	if [[ -n $current_step ]]; then
		say "FAILED in $current_step (exit $rc)"
	else
		say "FAILED before any step ran (exit $rc)"
	fi
	say "Log: $BUNNY_LOG"
	say "Steps are idempotent — fix the cause and re-run ./install.sh"
}
trap on_exit EXIT

# The rest of the preconditions, still before the first change. These can use
# `die`, which also records the reason in the log.

[[ -d $STEP_DIR ]] || die "no steps directory at $STEP_DIR"

mapfile -t steps < <(
	find "$STEP_DIR" -maxdepth 1 -type f -name '[0-9][0-9]-*.sh' -printf '%f\n' | sort
)
((${#steps[@]} > 0)) || die "no numbered steps found in $STEP_DIR"

for s in "${steps[@]}"; do
	[[ -x "$STEP_DIR/$s" ]] || die "$s is not executable — chmod +x it"
done

# Prove escalation works before anything is changed, so any password prompt
# happens here rather than three minutes in. Not a bare `sudo -v`: that prompts
# even under NOPASSWD, which fails over a non-interactive ssh.
if ! $dry_run; then
	if sudo -n true 2>/dev/null; then
		: # can escalate with no prompt at all
	elif [[ -t 0 ]]; then
		sudo -v || die "cannot escalate with sudo — is your user in a sudo-capable group?"
	else
		die "sudo needs a password and there is no terminal to type it into — run this from a real terminal, or 'ssh -t'"
	fi
fi

# Go.
say "Bunny — installing from $BUNNY_ROOT"
say "Log: $BUNNY_LOG"
say "Steps: ${steps[*]}"

export BUNNY_ROOT BUNNY_LOG
if $dry_run; then
	say "DRY RUN: steps will report what they would change and write nothing"
	export BUNNY_DRY_RUN=1
fi

for s in "${steps[@]}"; do
	current_step=$s
	say ""
	say "── $s"
	# The step's own output goes to the log as well as the terminal, so a failure is
	# diagnosable afterwards. `pipefail` is set, so the pipeline still fails when the
	# step does; `2>&1 ... >&2` keeps it all on stderr.
	"$STEP_DIR/$s" 2>&1 | tee -a "$BUNNY_LOG" >&2
	current_step=
done

say ""
if $dry_run; then
	say "Dry run complete — nothing was changed."
	exit 0
fi
say "Bunny is installed."

# assets/ascii/bunnies/hare.txt, embedded so a successful install cannot end by
# failing to find a decoration. Quoted heredoc: nothing here may be expanded.
cat >&2 <<'HARE'

             \\ \\
              \\ \\
               \ ,.`_
               |   0 \
      _ _ ,,._ j   == )
,_ /cf^  T&T` ~~~  V
\_|._ _  ~ ,,      )
    /!/ /!/  `\\``\\
    /v, /v,   \\_ \\_
    -"$ -"$    \"$ \"$

HARE
