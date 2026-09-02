#!/usr/bin/env bash
# snapper: pre/post snapshots around pacman, capped, with no timeline.
# CHOICES.md `snapshot-system` (+ `snapshot-bloat`, `docker-storage-quota`).
#
# The deviations, and only the deviations. Each was read by diffing the live file
# against /usr/share/snapper/config-templates/default rather than from the
# ledger's prose. Note what is absent: `FREE_LIMIT="0.2"` is in the ledger's text
# but is already the template default, so it is not set here.
#
#   SPACE_LIMIT=0.08            ~20 GiB of a 249 GiB fs (template: 0.5)
#   NUMBER_LIMIT=2-15           floor 2: the newest pre/post pair always survives
#                               and is exempt from the byte cap, so rollback
#                               across the most recent transaction is guaranteed.
#   NUMBER_LIMIT_IMPORTANT=0-5  floor 0, no exemption
#   NUMBER_MIN_AGE=1800         (template: 3600)
#   TIMELINE_CREATE=no          hourly timelines are gripe #2's engine
#
# QGROUP is not set by hand. `snapper setup-quota` creates 1/0 and writes it, and
# that qgroup is what SPACE_LIMIT runs on — man 5 snapper-configs: "the btrfs quota
# group used for space aware cleanup algorithms". Without it the byte cap silently
# does nothing. See benchmarks/4.29.
#
# The row also says the timeline timer is never enabled; on bunne-test it was,
# waking hourly to run a service that reads TIMELINE_CREATE and does nothing. This
# step disables it.
#
# Idempotent throughout; honours BUNNY_DRY_RUN.
#
# Usage: 40-snapshots.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

# `snapper create-config` writes this 0640 root:root, so every read of it needs
# sudo — including the verification greps below.
readonly CFG=/etc/snapper/configs/root
say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}

# The config has to exist before anything can be set on it.
if [[ -f $CFG ]]; then
	say "  = snapper config 'root' exists"
elif [[ -n $dry ]]; then
	say "  ~ would create the snapper config for /"
else
	# `snapper create-config` makes its own /.snapshots subvolume and refuses if
	# something is already there. On this layout `@snapshots` is always already
	# mounted there (README.md step 2), because a top-level `@snapshots` is what
	# survives the subvolume swap `rollback-method` picked — snapper's own nested
	# `.snapshots` would live inside `@`, so swapping `@` strands every snapshot in
	# the retired subvolume.
	#
	# The conflict is structural, and the resolution is the unmount / create / delete
	# / remount sequence the Arch wiki documents for this layout.
	#
	# It only runs on an empty /.snapshots: step two removes that directory, and a
	# failed unmount would then point `rmdir` at real snapshots.
	if mountpoint -q /.snapshots && [[ -n $(sudo ls -A /.snapshots) ]]; then
		say "  ! /.snapshots is mounted and NOT empty"
		say "    This step would have to unmount and recreate it, which is safe only"
		say "    when there is nothing in it. Look at what is there first:"
		say "      sudo ls -A /.snapshots"
		exit 1
	fi

	if mountpoint -q /.snapshots; then
		# Put the mount back whatever happens next — leaving @snapshots unmounted
		# would silently start writing snapshots into `@` itself.
		restore_snapshots_mount() {
			mountpoint -q /.snapshots && return 0
			sudo mkdir -p /.snapshots
			sudo mount /.snapshots 2>/dev/null || true
		}
		trap restore_snapshots_mount EXIT

		sudo umount /.snapshots
		sudo rmdir /.snapshots # rmdir, not rm -r: refuses if the unmount left anything
		sudo snapper -c root create-config /
		sudo btrfs subvolume delete /.snapshots >/dev/null
		sudo mkdir /.snapshots
		sudo mount /.snapshots
		sudo chmod 750 /.snapshots
		trap - EXIT
		say "  + created the snapper config, keeping @snapshots mounted at /.snapshots"
	else
		# Refuse rather than fall through. Without @snapshots mounted here,
		# `create-config` makes its own `.snapshots` inside `@` and everything looks
		# fine until a rollback swaps `@` and strands every snapshot. 00-preflight.sh
		# checks the same thing earlier; this is the backstop for a skipped preflight.
		say "  ! /.snapshots is not a mounted subvolume"
		say "    snapper would create its own inside @, and a rollback that swaps @"
		say "    would then strand every snapshot in the retired subvolume."
		say "    Expected: @snapshots mounted at /.snapshots (README.md step 2)."
		say "    Check with: findmnt /.snapshots"
		exit 1
	fi

	# The sequence above is only correct if the mount came back and it is still the
	# top-level @snapshots, not a fresh nested one.
	if ! findmnt -no OPTIONS /.snapshots | grep -q 'subvol=/@snapshots'; then
		say "  ! /.snapshots is not @snapshots any more — snapshots would land inside @"
		say "    check: findmnt /.snapshots"
		exit 1
	fi
fi

# Which configs the timers act on.
if grep -q '^SNAPPER_CONFIGS="root"$' /etc/conf.d/snapper; then
	say "  = /etc/conf.d/snapper lists root"
elif [[ -n $dry ]]; then
	say "  ~ would set SNAPPER_CONFIGS=\"root\" in /etc/conf.d/snapper"
else
	sudo sed -i 's|^SNAPPER_CONFIGS=.*|SNAPPER_CONFIGS="root"|' /etc/conf.d/snapper
	grep -q '^SNAPPER_CONFIGS="root"$' /etc/conf.d/snapper || {
		say "  ! could not set SNAPPER_CONFIGS in /etc/conf.d/snapper"
		exit 1
	}
	say "  + set SNAPPER_CONFIGS=\"root\""
fi

# The five values, read from the config file rather than `snapper get-config`,
# because the file is the thing being set.
set_cfg() {
	local key=$1 val=$2
	if sudo grep -q "^${key}=\"${val}\"$" "$CFG"; then
		say "  = ${key}=${val}"
	elif [[ -n $dry ]]; then
		say "  ~ would set ${key}=${val}"
	else
		sudo snapper -c root set-config "${key}=${val}"
		sudo grep -q "^${key}=\"${val}\"$" "$CFG" || {
			say "  ! ${key} did not take"
			exit 1
		}
		say "  + ${key}=${val}"
	fi
}
set_cfg SPACE_LIMIT 0.08
set_cfg NUMBER_LIMIT 2-15
set_cfg NUMBER_LIMIT_IMPORTANT 0-5
set_cfg NUMBER_MIN_AGE 1800
set_cfg TIMELINE_CREATE no

# The qgroup the byte cap runs on.
if sudo grep -q '^QGROUP="[^"]\+"$' "$CFG"; then
	say "  = QGROUP set ($(sudo sed -n 's/^QGROUP="\(.*\)"$/\1/p' "$CFG"))"
elif [[ -n $dry ]]; then
	say "  ~ would run snapper setup-quota"
else
	sudo snapper -c root setup-quota
	sudo grep -q '^QGROUP="[^"]\+"$' "$CFG" || {
		say "  ! setup-quota left QGROUP empty — SPACE_LIMIT would do nothing"
		exit 1
	}
	say "  + snapper setup-quota"
fi

# Timers. cleanup enforces the cap (daily); timeline must be off, since
# TIMELINE_CREATE=no already makes it a no-op and leaving it enabled costs 24
# wakeups a day.
want_timer() {
	local unit=$1 state=$2 now
	now=$(systemctl is-enabled "$unit" 2>/dev/null || true)
	if [[ $now == "$state" ]]; then
		say "  = $unit $state"
	elif [[ -n $dry ]]; then
		say "  ~ would $([[ $state == enabled ]] && echo enable || echo disable) $unit (currently ${now:-unknown})"
	else
		if [[ $state == enabled ]]; then
			sudo systemctl enable --now "$unit"
		else
			sudo systemctl disable --now "$unit"
		fi
		say "  + $unit $state"
	fi
}
want_timer snapper-cleanup.timer enabled
want_timer snapper-timeline.timer disabled

if [[ -n $dry ]]; then exit 0; fi

# Prove the pieces are wired. snap-pac is what makes any of this happen: without
# its pacman hooks nothing ever takes a snapshot and every setting above is
# decoration. That is this row's own history — the plumbing existed for weeks
# while nothing was taking snapshots.
hooks=$(find /usr/share/libalpm/hooks -name '*snap-pac*' 2>/dev/null | wc -l)
if ((hooks == 0)); then
	say "  ! no snap-pac pacman hooks — nothing will ever take a snapshot"
	exit 1
fi
say "  ✓ snap-pac hooks present ($hooks)"

# And that snapper can read the config it was just given.
sudo snapper -c root list >/dev/null || {
	say "  ! snapper cannot list config 'root'"
	exit 1
}
say "  ✓ snapper config 'root' usable ($(sudo snapper -c root --no-headers list | wc -l) snapshots)"
