# Bunny shell helpers. CHOICES.md `shell-helpers`.
#
# Function definitions only — nothing here runs until it is called by name, so
# this file costs one `source` at shell startup and nothing per prompt.

# git.

# Resolve the repo's default branch. Prefers the remote's own HEAD, falls back to
# whichever of main/master exists locally. Two callers, which is normally not
# worth an abstraction — it survives because the fallback chain is three branches
# long and inlining it twice is how the two drift apart.
_git_default_branch() {
	local def
	def=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
	if [[ -n $def ]]; then
		printf '%s\n' "${def#origin/}"
	elif git show-ref --verify --quiet refs/heads/main; then
		printf 'main\n'
	else
		printf 'master\n'
	fi
}

# Update the default branch without leaving the branch you are on.
gu() {
	local current default stashed=0
	current=$(git rev-parse --abbrev-ref HEAD) || return
	default=$(_git_default_branch)

	# `diff-index` misses untracked files, so both are checked. The flag is the
	# point: an unconditional `git stash pop` on a clean tree pops whatever
	# unrelated stash happened to be on top.
	if ! git diff-index --quiet HEAD -- || [[ -n $(git ls-files --others --exclude-standard) ]]; then
		git stash --include-untracked || return
		stashed=1
	fi

	git checkout "$default" && git pull && git checkout "$current"
	((stashed)) && git stash pop
	git status
}

# `gu`, then rebase the current branch onto the freshly-pulled default.
gur() {
	gu && git rebase "$(_git_default_branch)"
}

# Disk forensics. 02-functionality.md C9. `disk-alert` says that the disk is
# filling; these say why.

_hr() { printf '\n== %s ==\n\n' "$*"; }

diagnose() {
	_hr "df -h /"
	df -h /
	_hr "btrfs filesystem usage /"
	sudo btrfs filesystem usage /
	_hr "btrfs filesystem df / (allocated vs used -- explains df/du mismatches)"
	sudo btrfs filesystem df /
	_hr "biggest dirs on /"
	sudo du -xhd1 / 2>/dev/null | sort -h | tail
	_hr "biggest dirs in ~"
	du -xhd1 ~ 2>/dev/null | sort -h | tail
	_hr "biggest individual files on / (>200M)"
	sudo find / -xdev -type f -size +200M -exec du -h {} + 2>/dev/null | sort -rh | head -20
	# Docker is the most common cause, and RECLAIMABLE is the answer to "what can
	# I delete" — but only if the daemon is up. Socket activation means it usually
	# is not, hence the check rather than an error.
	if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
		_hr "docker usage (RECLAIMABLE column = safe to prune)"
		docker system df -v
	fi
}

diagnose_snapshots() {
	_hr "snapper -c root list"
	sudo snapper -c root list
	# Sorted by the exclusive column, the only one that answers "how much do I get
	# back if I delete this" — shared bytes free nothing. 40-snapshots.sh already
	# enabled qgroup accounting, so this does not `quota enable` or `rescan -w`.
	_hr "btrfs qgroup show -p --raw / (sorted by exclusive size)"
	sudo btrfs qgroup show -p --raw / | sort -k3 -h
	_hr "cleanup"
	printf 'sudo snapper -c root delete <num> [<num>...] to remove snapshots\n'
}

# vpn. One alias per `.ovpn` file dropped in $XDG_CONFIG_HOME/bunny/vpn/, named
# for the profile's first letter — `dev.ovpn` becomes `vd`. 02-functionality.md
# C8. The shape is the predecessor's scripts/vpn.sh with the script taken out:
# that generated a `.vpnrc` which then had to be sourced and regenerated whenever
# a profile changed. A glob plus `alias` does the same job with no fork and
# nothing on disk.
#
# A directory and not a list because employer and client work never appears in
# this repo, not as a config, not as a path, not as an alias (CLAUDE.md). This
# reads whatever is there and names nothing; the directory is untracked and
# install.sh does not create it.
#
# Named limitation: two profiles starting with the same letter collide and the
# last one wins silently. Left as-is because the fix is either an alias nobody's
# fingers know or a startup-time warning on every shell.
for _bunny_vpn in "${XDG_CONFIG_HOME:-$HOME/.config}"/bunny/vpn/*.ovpn; do
	[[ -e $_bunny_vpn ]] || break
	_bunny_vpn_name=${_bunny_vpn##*/}
	# shellcheck disable=SC2139 # expanded now on purpose: the path is fixed at startup
	alias "v${_bunny_vpn_name:0:1}"="sudo openvpn --config \"$_bunny_vpn\""
done
unset _bunny_vpn _bunny_vpn_name
