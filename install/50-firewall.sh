#!/usr/bin/env bash
# nftables, with Arch's own shipped /etc/nftables.conf as the ruleset.
#
# viacoffee/dotfiles uses ufw here. nftables is kept instead because this machine
# runs Docker, and Docker writes its own rules directly into the kernel's tables —
# ufw's chains are simply not on the path a container's traffic takes, so a
# container is reachable regardless of what ufw was told. Keeping the one firewall
# Docker actually interacts with is the difference between a rule that holds and a
# rule that reads well.
#
# No firewall config file is authored here. Arch's shipped ruleset already does
# what is wanted -- drop inbound, allow established, allow outbound -- and the one
# amendment below is appended to it, so a diff against the stock file is two rules.

log "Configuring nftables..."

if systemctl is-enabled --quiet nftables.service 2>/dev/null; then
	info "nftables.service already enabled"
else
	run_logged "Enable nftables.service" sudo systemctl enable --now nftables.service
fi

readonly NFT_CONF=/etc/nftables.conf
readonly NFT_MARKER="BunnE: docker bridge forwarding"

# Arch's shipped ruleset defines `chain forward { type filter hook forward
# priority filter; policy drop; }` with no rules in it, so nothing ever accepts a
# forwarded packet and a container cannot reach anything past its own gateway.
#
# The symptom is not firewall-shaped: `ping` to the docker0 gateway still works,
# because that goes through `input`, which allows icmp. What fails is name
# resolution and every outbound connection, so it looks like DNS or a VPN. Found
# the hard way on 2026-09-02, after going through docker0 link state, iptables,
# nftables base-chain ordering and a red-herring VPN disconnect first. The
# ArchWiki's Docker page documents the same conflict.
#
# Docker still does its own NAT -- the MASQUERADE rule for 172.17.0.0/16 appears
# in `ip nat POSTROUTING` as soon as dockerd starts. The gap is only the parallel
# `inet filter forward` chain the shipped ruleset installs at the same hook.
# Guarded on the rule text, not on the marker comment. An earlier version of this
# repo wrote the same two rules under a slightly different comment; matching the
# comment would have missed them and appended a duplicate pair on every run.
if grep -qE '^[[:space:]]*iifname "docker0" accept' "$NFT_CONF" 2>/dev/null; then
	info "$NFT_CONF already allows docker0 through the forward chain"
else
	staged_nft=$(mktemp)

	# Inserted after the FIRST `policy drop` following `chain forward {` -- the
	# input chain carries that same line, and only forward's is empty.
	if ! awk -v marker="$NFT_MARKER" '
		/chain[[:space:]]+forward[[:space:]]*\{/ { in_fwd = 1 }
		in_fwd && /policy[[:space:]]+drop/ && !patched {
			print
			print ""
			print "    # " marker
			print "    iifname \"docker0\" accept comment \"allow docker bridge forwarding\""
			print "    oifname \"docker0\" accept comment \"allow docker bridge forwarding\""
			patched = 1
			next
		}
		{ print }
		END { exit !patched }
	' "$NFT_CONF" >"$staged_nft"; then
		rm -f "$staged_nft"
		error "Could not find 'chain forward { ... policy drop }' in $NFT_CONF to patch"
		error "The shipped ruleset's shape has changed since this was written"
		return 1
	fi

	# nft's own parser, before the file becomes the live ruleset.
	if ! sudo nft -c -f "$staged_nft"; then
		rm -f "$staged_nft"
		error "The patched ruleset failed nft's validation — not applying it"
		return 1
	fi

	sudo install -m644 "$staged_nft" "$NFT_CONF"
	rm -f "$staged_nft"
	run_logged "Reloading nftables" sudo nft -f "$NFT_CONF"
	success "Patched $NFT_CONF to allow docker0 forwarding"
fi

# nftables.service is Type=oneshot with no RemainAfterExit, so it goes inactive
# with exit 0 once the ruleset is loaded -- correct operation, not failure. An
# earlier version of this check demanded `active` and would have failed every
# install. The question that means something for a firewall is whether a ruleset
# is loaded, so ask that.
if [[ -z $(sudo nft list ruleset 2>/dev/null) ]]; then
	error "nftables has no ruleset loaded — nothing is being filtered"
	error "check: systemctl status nftables, and $NFT_CONF"
	return 1
fi
success "nftables filtering with a loaded ruleset"
