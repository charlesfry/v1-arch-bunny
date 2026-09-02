#!/usr/bin/env bash
# Docker's bridge traffic through nftables' `forward` hook.
# CHOICES.md `firewall` (nftables, Arch's shipped ruleset — amended 2026-09-02).
#
# Arch's shipped /etc/nftables.conf — the ruleset 25-services.sh proves is loaded —
# defines `chain forward { type filter hook forward priority filter; policy drop; }`
# with zero rules. Nothing in the stock file ever accepts a forwarded packet, so a
# container's traffic to anywhere past its own gateway is silently dropped. `ping`
# to the docker0 gateway address still works — that goes through `input`, which
# explicitly allows icmp — so the failure looks exactly like a DNS or VPN problem
# and not like a firewall at all. Found the hard way, 2026-09-02: `image_builder.py`
# builds failing with `Could not resolve host: conda.anaconda.org` inside the
# container, traced through docker0 link state, iptables, nftables base-chain
# ordering, and a red-herring OpenVPN disconnect before landing on this. Confirmed
# against the ArchWiki's own Docker section, which documents the same conflict.
#
# Docker still manages its own NAT — `ip nat POSTROUTING` already carries the
# MASQUERADE rule for 172.17.0.0/16 the moment dockerd starts, with `"iptables":
# true` (the default, unchanged here). The gap is purely the parallel `inet filter
# forward` chain the shipped ruleset installs at the same hook, so the fix is two
# `accept` rules for the docker0 interface — not a masquerade rule of its own.
#
# This appends to the shipped file rather than replacing it, so CHOICES.md's "no
# config file is carried by this repo" still holds in spirit: nothing here is
# authored from scratch, and a diff against the stock file is two lines.
#
# Idempotent, marked by its own comment string in the file (same convention
# 15-docker-subvols.sh uses for its fstab line); honours BUNNY_DRY_RUN. Runs after
# 25-services.sh, which is what proves nftables.service loaded a ruleset in the
# first place — patching a ruleset that was never confirmed loaded would be
# pointless.
#
# Usage: 26-docker-nftables.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}

readonly CONF=/etc/nftables.conf
readonly MARKER="Bunny: docker bridge forwarding (CHOICES.md firewall)"

if grep -qF "$MARKER" "$CONF" 2>/dev/null; then
	say "  = $CONF already allows docker0 through the forward chain"
else
	if [[ -n $dry ]]; then
		say "  ~ would patch $CONF: allow docker0 through the forward chain"
		exit 0
	fi

	tmp=$(mktemp)
	trap 'rm -f "$tmp"' EXIT

	# Inserted after the *first* `policy drop` following `chain forward {`, not
	# `chain input`'s — both chains carry that line, and only forward's is empty.
	awk -v marker="$MARKER" '
		/chain[[:space:]]+forward[[:space:]]*\{/ { in_fwd = 1 }
		in_fwd && /policy[[:space:]]+drop/ && !done {
			print
			print ""
			print "    # " marker
			print "    iifname \"docker0\" accept comment \"allow docker bridge forwarding\""
			print "    oifname \"docker0\" accept comment \"allow docker bridge forwarding\""
			done = 1
			next
		}
		{ print }
		END { exit !done }
	' "$CONF" >"$tmp" || {
		say "  ! could not find chain forward { policy drop } in $CONF to patch"
		say "    the shipped ruleset's shape has changed since this was written —"
		say "    patch it by hand, see CHOICES.md 'firewall'"
		exit 1
	}

	sudo nft -c -f "$tmp" || {
		say "  ! patched ruleset failed nft's own validation — not applying it"
		exit 1
	}

	sudo tee "$CONF" <"$tmp" >/dev/null
	sudo nft -f "$CONF"
	say "  + patched $CONF and reloaded nftables"
fi

if [[ -n $dry ]]; then exit 0; fi

if sudo nft list chain inet filter forward 2>/dev/null | grep -q 'iifname "docker0" accept'; then
	say "  ✓ docker0 forwarding allowed"
else
	say "  ! docker0 accept rule is not in the live ruleset — reload may have failed"
	say "    check: sudo nft list chain inet filter forward"
	exit 1
fi
