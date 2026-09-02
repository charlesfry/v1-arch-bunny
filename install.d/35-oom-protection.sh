#!/usr/bin/env bash
# systemd-oomd: kill the worst cgroup under memory/swap pressure, before the
# kernel OOM-killer thrashes the whole machine. CHOICES.md `oom-protection`.
#
# No package and no new daemon class — systemd-oomd ships inside systemd, and the
# 1.4 MB it costs is systemd's own manager overhead. That is why priority 2b could
# accept it.
#
# The two drop-ins, and why each scope:
#
#   -.slice        ManagedOOMSwap=kill            the root slice, so the whole
#                                                 system is watched for swap
#                                                 exhaustion.
#   user@.service  ManagedOOMSwap=kill            the desktop session, where the
#                  ManagedOOMMemoryPressure=kill  hog actually runs. Pressure-kill
#                                                 is scoped here and not to the
#                                                 root, which would put init in
#                                                 scope.
#
# The uid is read rather than assumed: hardcoding `user@1000.service` makes the
# verification below pass or fail for the wrong reason on a box whose desktop user
# was not the first created.
#
# The limits are not set here. `oomctl` reports the shipped defaults — swap 90%,
# pressure 60% over 30 s — and nothing in the ratified row asks for different
# numbers.
#
# Runs after 30-zram.sh as a dependency, not a preference: oomd's swap-kill path
# is inert with no swap, and zram is the only swap this layout has.
#
# What is proven and what is not (benchmarks/4.18): the swap-kill canary passed —
# oomd killed exactly the hog cgroup at >90% swap, the kernel OOM killer never
# fired. The pressure-kill path is configured and unexercised; the test ramp
# allocated too fast to build sustained PSI.
#
# Idempotent; honours BUNNY_DRY_RUN.
#
# Usage: 35-oom-protection.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}

install_file() {
	local path=$1 content=$2
	if sudo test -f "$path" && [[ $(sudo cat -- "$path") == "$content" ]]; then
		say "  = $path already correct"
		return
	fi
	if [[ -n $dry ]]; then
		say "  ~ would write $path"
		return
	fi
	sudo install -Dm644 /dev/stdin "$path" <<<"$content"
	say "  + wrote $path"
}

install_file /etc/systemd/system/-.slice.d/10-oomd.conf "$(
	cat <<'EOF'
[Slice]
ManagedOOMSwap=kill
EOF
)"

install_file /etc/systemd/system/user@.service.d/10-oomd.conf "$(
	cat <<'EOF'
[Service]
ManagedOOMMemoryPressure=kill
ManagedOOMSwap=kill
EOF
)"

if [[ $(systemctl is-enabled systemd-oomd.service 2>/dev/null || true) == enabled ]]; then
	say "  = systemd-oomd.service enabled"
elif [[ -n $dry ]]; then
	say "  ~ would enable systemd-oomd.service"
else
	sudo systemctl enable --now systemd-oomd.service
	say "  + enabled systemd-oomd.service"
fi

if [[ -n $dry ]]; then exit 0; fi

# daemon-reload is enough: the drop-ins are unit settings, and the manager hands
# the resulting ManagedOOM* values to oomd. Restarting oomd would bounce a working
# daemon on every install run for nothing.
sudo systemctl daemon-reload

# Prove oomd loaded them, not that the files parse. `systemctl show` would report
# the same values off the unit files alone, so it cannot tell a working
# configuration from one oomd never picked up. `oomctl` prints what the running
# daemon is watching.
#
# Read the two sections separately. Grepping the whole `oomctl` output for each
# cgroup path cannot fail usefully: the user session appears under Swap Monitored,
# so the check passed whether or not memory-pressure monitoring existed at all.
#
# `awk` ranges rather than `sed`: a `sed` range ending at
# /Memory Pressure Monitored/ prints that header and stops, so reading the
# pressure list that way always shows it empty.
uid=$(id -u)
readonly USER_CG="/user.slice/user-$uid.slice/user@$uid.service"

oom=$(sudo oomctl)
swap_section=$(awk '/^Swap Monitored CGroups:/{f=1;next} /^Memory Pressure Monitored CGroups:/{f=0} f' <<<"$oom")
pressure_section=$(awk '/^Memory Pressure Monitored CGroups:/{f=1;next} f' <<<"$oom")

check_section() {
	local label=$1 body=$2 path=$3
	if grep -qF "Path: $path" <<<"$body"; then
		say "  ✓ $label: $path"
		return
	fi
	say "  ! oomd is not $label $path — the drop-in exists but is not in effect"
	say "    check: sudo oomctl"
	# Measured across a boot on bunne-test: both sections are fully populated by
	# 14 s uptime and stay that way (60 samples over 3 minutes). So this is a real
	# failure, not a race.
	say "    (both lists populate by ~14 s of uptime, so this is not a startup race)"
	exit 1
}

check_section "swap-monitoring" "$swap_section" "/"
check_section "swap-monitoring" "$swap_section" "$USER_CG"
check_section "pressure-monitoring" "$pressure_section" "$USER_CG"

# The swap half of this row is the half that was canaried, and it is dead without
# swap. A zram failure in step 30 would silently halve this protection rather than
# break it.
if ! swapon --show=NAME --noheadings | grep -q .; then
	say "  ! no swap active — oomd's swap-kill path (the one benchmarks/4.18 proved)"
	say "    cannot fire. See install.d/30-zram.sh."
	exit 1
fi
say "  ✓ swap present: $(swapon --show=SIZE --noheadings | tr -d ' ' | paste -sd+ -)"
