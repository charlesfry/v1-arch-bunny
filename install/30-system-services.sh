#!/usr/bin/env bash
# System services: network, bluetooth, the display manager, snapshots, power, and
# the memory pressure handler.
#
# The network stack is iwd for wifi and systemd-networkd for everything else,
# replacing NetworkManager. iwd does its own DHCP on wireless, so networkd's
# generated wlan/wwan files are masked rather than left to compete for the lease.

info "Configuring networking, system services, and power..."

enable_unit() {
	local unit=$1
	if systemctl is-enabled --quiet "$unit" 2>/dev/null; then
		info "$unit already enabled"
	else
		run_logged "Enable $unit" sudo systemctl enable "$unit"
	fi
}

disable_unit() {
	local unit=$1
	if systemctl is-enabled --quiet "$unit" 2>/dev/null; then
		run_logged "Disable $unit" sudo systemctl disable "$unit"
	fi
}

enable_unit bluetooth.service

# NetworkManager and iwd both want to own the wireless device.
#
# iwd does not read NetworkManager's saved connections, so a machine installed
# with NetworkManager (which is what archinstall gives you, and what got you
# online to run this) has no known networks under iwd and comes back from the
# next reboot with no wifi. Say so here rather than letting it be discovered
# after the reboot, with no network to look up the fix on.
if systemctl is-enabled --quiet NetworkManager.service 2>/dev/null &&
	! compgen -G '/var/lib/iwd/*.psk' >/dev/null; then
	warn "Switching from NetworkManager to iwd, which has no saved networks yet."
	warn "Join your wifi with 'impala' (or iwctl) BEFORE rebooting, or you will"
	warn "come up with no network and no way to look this up."
fi
disable_unit NetworkManager.service
enable_unit systemd-networkd.service
enable_unit iwd.service

log "Configuring iwd's built-in DHCP client"
sudo install -Dm644 "$BUNNY_DEFAULTS/iwd/main.conf" /etc/iwd/main.conf

log "Restricting systemd-networkd to wired interfaces"
sudo install -Dm644 "$BUNNY_DEFAULTS/networkd/20-ethernet.network" \
	/etc/systemd/network/20-ethernet.network
for generated in 20-wlan.network 20-wwan.network; do
	if [[ -f /etc/systemd/network/$generated && ! -L /etc/systemd/network/$generated ]]; then
		run_logged "Masking /etc/systemd/network/$generated" \
			sudo ln -sf /dev/null "/etc/systemd/network/$generated"
	fi
done

# wait-online blocks boot for its full timeout whenever the ethernet port has no
# cable, which on a laptop is almost always.
disable_unit systemd-networkd-wait-online.service

enable_unit systemd-resolved.service
if [[ ! -L /etc/resolv.conf ]] || [[ $(readlink /etc/resolv.conf) != *stub-resolv* ]]; then
	run_logged "Pointing /etc/resolv.conf at the systemd-resolved stub" \
		sudo ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
fi

enable_unit limine-snapper-sync.service
# The timeline timer takes periodic snapshots. 13-bootloader.sh sets
# TIMELINE_CREATE="no", so the timer would fire and do nothing; snap-pac brackets
# pacman transactions, which is when things actually break.
disable_unit snapper-timeline.timer

enable_unit greetd.service
enable_unit power-profiles-daemon.service

log "Configuring shutdown timeout"
sudo install -Dm644 "$BUNNY_DEFAULTS/systemd/faster-shutdown.conf" \
	/etc/systemd/system.conf.d/10-faster-shutdown.conf

# systemd-oomd, so a runaway process is killed by cgroup before the kernel's own
# OOM killer thrashes the whole machine. The drop-ins are what make it act: oomd
# monitors nothing until a slice opts in.
log "Configuring systemd-oomd"
sudo install -Dm644 "$BUNNY_DEFAULTS/systemd/oomd-root-slice.conf" \
	/etc/systemd/system/-.slice.d/10-oomd.conf
sudo install -Dm644 "$BUNNY_DEFAULTS/systemd/oomd-user-service.conf" \
	/etc/systemd/system/user@.service.d/10-oomd.conf
enable_unit systemd-oomd.service

run_logged "Reloading systemd manager" sudo systemctl daemon-reload

# Prove oomd picked the drop-ins up rather than that the files parse. `systemctl
# show` reports the same values straight off the unit files, so it cannot tell a
# working configuration from one the daemon never read. `oomctl` prints what the
# running daemon is actually watching.
if systemctl is-active --quiet systemd-oomd.service; then
	if sudo oomctl 2>/dev/null | grep -q 'Swap Monitored CGroups'; then
		success "systemd-oomd is monitoring cgroups"
	else
		error "systemd-oomd is running but monitoring nothing — the drop-ins were not applied"
		return 1
	fi
else
	# Expected: enable without --now, so it starts at the next boot.
	info "systemd-oomd is enabled but not yet running; it starts at the next boot"
fi

success "System services configured"
