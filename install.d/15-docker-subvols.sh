#!/usr/bin/env bash
# Docker's bytes on their own top-level btrfs subvolumes, mounted from /etc/fstab.
# CHOICES.md `docker-storage-quota` (which also carries `snapshot-bloat`).
#
# What that buys, in the order the row argues it:
#
#   1. A subvolume boundary is not crossed by `btrfs subvolume snapshot`, so
#      Docker's images are absent from every snapshot of `@` without snapper
#      needing a filter. That is gripe #2.
#   2. Top level, not nested inside `@`. Nesting also keeps the bytes out of a
#      snapshot, but a rollback then hands the new `@` an empty directory at each
#      path: Docker sees no images, the old data is stranded in the retired `@`,
#      and Docker starts writing to an ordinary directory on `@` — inside every
#      future snapshot.
#   3. Both paths, not just /var/lib/docker. Under the containerd snapshotter
#      (Arch's default since docker 29) the image layers live in
#      /var/lib/containerd; /var/lib/docker holds volumes and the merged overlay
#      mounts. Capping only the latter caps nothing that grew.
#
# Accounting is enabled, limits are NOT set, and an existing limit is cleared.
# `benchmarks/4.27` drove `@containerd` into its cap and btrfs failed to roll back
# an fs-verity item for want of quota'd metadata space: forced readonly on the
# whole filesystem, `remount,rw` refused, cleared only by a reboot. A qgroup limit
# is scoped to a subvolume, forced-readonly to the filesystem, so a cap meant to
# contain Docker took `/` and `/home` with it. The protection is `disk-alert`,
# which reads the same accounting at 80%.
#
# These are created here rather than in the archinstall JSON because `disk_config`
# was dropped from both JSONs on 2026-08-28 — a partition layout is absolute
# sector offsets computed on one disk. With no `disk_config` there is nowhere for
# the subvolumes to live. It also keeps the manual partitioning short: these two
# are the only subvolumes that need not exist at install time, since a mount
# placed over an empty directory hides nothing.
#
# Runs before 20-packages.sh because a mount placed over a directory that already
# has bytes in it hides them. Installing docker first would leave the daemon's own
# directories on `@`.
#
# Not a migration tool: if either path already holds data outside its subvolume
# this step refuses and points at
# benchmarks/instruments/4.24-docker-subvol-promote.sh, which does the
# snapshot-and-delete promotion and guards the nested-layer hazard.
#
# Idempotent; honours BUNNY_DRY_RUN.
#
# Usage: 15-docker-subvols.sh [--help]
set -Eeuo pipefail

case "${1-}" in
-h | --help)
	sed -n '2,/^set -/p' "$0" | sed 's|^# \?||;$d'
	exit
	;;
esac

say() { printf '%s\n' "$*" >&2; }
dry=${BUNNY_DRY_RUN:-}

# subvolume : mountpoint : mode. The modes are what the daemons create for
# themselves (docker 0710, containerd 0700), not a choice made here. They have to
# be applied to the mounted subvolume: btrfs makes a new subvolume's root 0755,
# and the mountpoint's own mode disappears under the mount.
readonly WANT=(
	'@containerd:/var/lib/containerd:0700'
	'@dockervol:/var/lib/docker:0710'
)

uuid=$(findmnt -no UUID /)
[[ -n $uuid ]] || {
	say "  ! cannot read the UUID of / — is this the btrfs machine preflight checked?"
	exit 1
}

# The btrfs top level (subvolid=5) is not mounted anywhere on this layout, and a
# top-level subvolume can only be created from there. Mount it briefly rather than
# leaving a permanent mountpoint around for one command.
top=
# Written with `if`, not an AND-list: a false AND-list is itself a failed command
# under `set -e`, and this runs from the EXIT trap, where exiting early leaves the
# top level mounted.
cleanup() {
	if [[ -n $top ]]; then
		if mountpoint -q "$top"; then sudo umount "$top"; fi
		sudo rmdir "$top"
	fi
}
mount_top() {
	[[ -n $top ]] && return 0
	top=$(sudo mktemp -d /run/bunny-btrfs-top.XXXXXX)
	trap cleanup EXIT
	sudo mount -o subvolid=5 "UUID=$uuid" "$top"
}

# The strong check the guarantees rest on: not "does a subvolume by that name
# exist" but "is it the one mounted here right now".
mounted() { [[ $(findmnt -no OPTIONS "$2" 2>/dev/null || true) == *"subvol=/$1"* ]]; }

# Every refusal first, before the first mount. Checking per entry left a run
# aborting with /var/lib/containerd already mounted and fstab already edited.
for entry in "${WANT[@]}"; do
	IFS=: read -r sub dir _ <<<"$entry"
	if mounted "$sub" "$dir"; then continue; fi
	# `-mindepth 1` because the directory itself existing is fine and expected.
	if [[ -d $dir ]] && sudo find "$dir" -mindepth 1 -print -quit | grep -q .; then
		say "  ! $dir already holds data and is not mounted from $sub"
		say "    Mounting over it would hide those bytes, not move them."
		say "    Use benchmarks/instruments/4.24-docker-subvol-promote.sh, which"
		say "    promotes in place and refuses when nested image layers would be lost."
		exit 1
	fi
done

changed=false

for entry in "${WANT[@]}"; do
	IFS=: read -r sub dir _ <<<"$entry"

	if mounted "$sub" "$dir"; then
		say "  = $dir is on $sub"
		continue
	fi

	if [[ -n $dry ]]; then
		say "  ~ would create subvolume $sub and mount it at $dir"
		continue
	fi

	mount_top
	if [[ -d "$top/$sub" ]]; then
		say "  = subvolume $sub exists"
	else
		sudo btrfs subvolume create "$top/$sub" >/dev/null
		say "  + created subvolume $sub"
	fi

	# Just the mountpoint. Its mode is irrelevant — the mount hides it — and the mode
	# that matters is enforced on the mounted subvolume root below.
	sudo mkdir -p -- "$dir"

	# Appended, never rewritten: an fstab line that already mounts this subvolume here
	# is left exactly as it is, whatever options it carries.
	if ! grep -q "subvol=/$sub\b" /etc/fstab; then
		printf '\n# Bunny: %s out of @ (CHOICES.md docker-storage-quota)\nUUID=%s\t%s\tbtrfs\trw,noatime,compress=zstd:1,subvol=/%s\t0 0\n' \
			"$dir" "$uuid" "$dir" "$sub" | sudo tee -a /etc/fstab >/dev/null
		say "  + fstab: $dir -> $sub"
	fi

	# daemon-reload regenerates the .mount units fstab's generator produces; without
	# it `mount -a` succeeds and systemd still believes the old fstab.
	sudo systemctl daemon-reload
	sudo mount "$dir"
	changed=true
	say "  + mounted $dir"
done

if [[ -n $dry ]]; then exit 0; fi

# Accounting on, limits off. `quota enable` on an already-quota'd filesystem is a
# no-op returning 0, so this needs no guard.
sudo btrfs quota enable /

# A rescan only after something changed — it walks the whole filesystem. A
# subvolume created while quotas are on accounts correctly from birth, but one
# that predates the enable is marked inconsistent, and an inconsistent qgroup
# reports numbers `disk-alert` would act on (4.5).
if $changed; then
	sudo btrfs quota rescan -w / >/dev/null
	say "  + btrfs quota rescan"
fi

for entry in "${WANT[@]}"; do
	IFS=: read -r sub dir mode <<<"$entry"

	if [[ $(stat -c %a "$dir") != "${mode#0}" ]]; then
		sudo chmod "$mode" "$dir"
		say "  + $dir mode $mode"
	fi

	# A qgroup that does not exist is what a silently-failed `quota enable` looks like
	# from here, and `disk-alert` treats a missing subvolume as a breach. `-f` asks
	# for the qgroup of this path; without it the command prints every qgroup on the
	# filesystem. `--sync` because qgroup figures count committed extents: a read
	# straight after a write reported 16 KiB for 200 MiB.
	line=$(sudo btrfs qgroup show -re --raw --sync -f "$dir" 2>/dev/null | awk '$1 ~ "^0/" {print; exit}')
	if [[ -z $line ]]; then
		say "  ! no qgroup for $dir — accounting is off, so disk-alert watches nothing"
		exit 1
	fi

	# A limit here is the 4.27 forced-readonly hazard, so clear it. Columns in order:
	# qgroupid, referenced, exclusive, max_referenced, max_exclusive.
	read -r _ referenced _ max_ref max_excl _ <<<"$line"
	if [[ $max_ref != none || $max_excl != none ]]; then
		sudo btrfs qgroup limit none "$dir"
		say "  + cleared the qgroup limit on $dir (4.27: a limit can force the whole fs read-only)"
	fi
	say "  ✓ $sub accounted, no limit ($(numfmt --to=iec "$referenced") referenced)"
done
