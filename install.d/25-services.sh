#!/usr/bin/env bash
# The docker group, and a check that the JSON's services really came up.
# CHOICES.md `firewall` and `docker`.
#
# archinstall enables `nftables.service` and `docker.socket`, and enabling is not
# running: a unit can be enabled and have failed to start, and /etc/nftables.conf
# can load into an empty ruleset, which from `is-enabled` looks exactly like a
# working firewall. So the enabling moved into the JSON and the proving stayed
# here.
#
# The group cannot move with them. scripts/guided.py creates users at line 136 and
# installs the additional packages at line 146, so the `docker` group does not
# exist yet when the account is made — `"groups": ["docker"]` in the creds file
# would silently do nothing.
#
# The group change needs a new login, which here means a reboot: the desktop
# session is started by autologin at boot, so there is no logout that reaches a
# fresh getty. This step says so rather than leaving you wondering why `docker ps`
# still says permission denied.
#
# Idempotent; honours BUNNY_DRY_RUN.
#
# Usage: 25-services.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}

readonly WANT=(nftables.service docker.socket)

# The services the JSON enabled.
for unit in "${WANT[@]}"; do
	if [[ $(systemctl is-enabled "$unit" 2>/dev/null || true) != enabled ]]; then
		say "  ! $unit is not enabled"
		say "    This repo's archinstall JSON enables it at install time."
		say "    On a machine installed some other way: sudo systemctl enable --now $unit"
		exit 1
	fi
done

# The docker group. Note it is root-equivalent: anyone who can run `docker` can
# mount the whole filesystem inside a container and write to it.
if id -nG "$USER" | grep -qw docker; then
	say "  = $USER is in the docker group"
elif [[ -n $dry ]]; then
	say "  ~ would add $USER to the docker group"
else
	sudo usermod -aG docker "$USER"
	say "  + added $USER to the docker group — takes effect after a reboot"
fi

if [[ -n $dry ]]; then exit 0; fi

# Prove the services did their job, which is not the same as `is-active`.
# `docker.socket` is a socket unit and stays active while it listens, so
# `is-active` is the right question for it.
#
# `nftables.service` is `Type=oneshot` with no `RemainAfterExit`, so once it has
# loaded the ruleset it goes `inactive (dead)` with exit 0 — correct operation, not
# failure. An earlier version demanded `active` for both and would have failed
# every install. The question that means something for a firewall is whether a
# ruleset is loaded, so that is what is asked.
state=$(systemctl is-active docker.socket 2>/dev/null || true)
if [[ $state != active ]]; then
	say "  ! docker.socket is enabled but $state"
	say "    check: systemctl status docker.socket"
	exit 1
fi

if [[ -z $(sudo nft list ruleset 2>/dev/null) ]]; then
	say "  ! nftables has no ruleset loaded — nothing is being filtered"
	say "    check: systemctl status nftables, and /etc/nftables.conf"
	exit 1
fi
say "  ✓ nftables filtering with a loaded ruleset, docker.socket listening"
