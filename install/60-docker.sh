#!/usr/bin/env bash
# Docker's bytes on their own btrfs subvolumes, and the docker group.
#
# This is the first of the three problems the project exists to fix. Under a
# single @ subvolume, image layers land inside every root snapshot, so snapshots
# balloon and the disk fills -- and a full disk is a priority-1 failure, not a
# tidiness one. Two top-level subvolumes mounted from /etc/fstab keep them out of
# @ entirely, which makes them invisible to snapper and separately accountable to
# btrfs quotas.
#
# Quotas are for accounting, not enforcement: no qgroup limit is set. A hard cap
# makes `docker pull` fail in ways Docker reports badly, and the disk-usage alert
# (80-disk-alert.sh) is the thing that actually gets looked at.

log "Configuring Docker storage..."

# subvolume:mountpoint:mode. 0710 on /var/lib/docker is upstream's own choice;
# 0700 on containerd's likewise. Anything looser lets a local user read image
# layers, which routinely contain credentials baked in at build time.
readonly DOCKER_SUBVOLS=(
	'@containerd:/var/lib/containerd:0700'
	'@dockervol:/var/lib/docker:0710'
)

root_uuid=$(findmnt -no UUID /)
if [[ -z $root_uuid ]]; then
	error "Cannot read the UUID of / — is this the btrfs machine preflight checked?"
	return 1
fi

# Cleaned up by an explicit call, not a trap: phases are sourced, so a `trap ...
# EXIT` here would replace install.sh's own EXIT trap, which is what regenerates
# boot artifacts if the run dies with generation still deferred. A leaked mount
# under /run is a tmpfs entry that a reboot clears; a lost boot image is not.
btrfs_top=
cleanup_btrfs_top() {
	if [[ -n $btrfs_top ]]; then
		if mountpoint -q "$btrfs_top"; then sudo umount "$btrfs_top"; fi
		sudo rmdir "$btrfs_top"
		btrfs_top=
	fi
}

# Subvolume creation needs the filesystem root (subvolid=5), which is not what is
# mounted at / -- that is @.
mount_btrfs_top() {
	[[ -n $btrfs_top ]] && return 0
	btrfs_top=$(sudo mktemp -d /run/bunny-btrfs-top.XXXXXX)
	sudo mount -o subvolid=5 "UUID=$root_uuid" "$btrfs_top"
}

subvol_mounted() { [[ $(findmnt -no OPTIONS "$2" 2>/dev/null || true) == *"subvol=/$1"* ]]; }

# Check every target before touching any of them. Mounting over a directory that
# already holds data hides those bytes rather than moving them, and Docker then
# reports a working install with every image silently gone.
for entry in "${DOCKER_SUBVOLS[@]}"; do
	IFS=: read -r subvol dir _ <<<"$entry"
	subvol_mounted "$subvol" "$dir" && continue
	if [[ -d $dir ]] && sudo find "$dir" -mindepth 1 -print -quit | grep -q .; then
		error "$dir already holds data and is not mounted from $subvol"
		error "Mounting over it would hide those bytes, not move them. Migrate first."
		return 1
	fi
done

subvols_changed=false
for entry in "${DOCKER_SUBVOLS[@]}"; do
	IFS=: read -r subvol dir mode <<<"$entry"

	if subvol_mounted "$subvol" "$dir"; then
		info "$dir is on $subvol"
	else
		mount_btrfs_top
		if [[ -d "$btrfs_top/$subvol" ]]; then
			info "Subvolume $subvol exists"
		else
			run_logged "Creating subvolume $subvol" \
				sudo btrfs subvolume create "$btrfs_top/$subvol"
		fi

		sudo mkdir -p -- "$dir"

		# No `compress=` here: compression is left to whatever the base install
		# chose for the filesystem, and image layers are already compressed.
		if ! grep -q "subvol=/$subvol\b" /etc/fstab; then
			printf '\n# BunnE: %s out of @, so image layers stay out of root snapshots\nUUID=%s\t%s\tbtrfs\trw,noatime,subvol=/%s\t0 0\n' \
				"$dir" "$root_uuid" "$dir" "$subvol" | sudo tee -a /etc/fstab >/dev/null
			success "fstab: $dir -> $subvol"
		fi

		sudo systemctl daemon-reload
		run_logged "Mounting $dir" sudo mount "$dir"
		subvols_changed=true
	fi

	if [[ $(stat -c %a "$dir") != "${mode#0}" ]]; then
		run_logged "Setting mode $mode on $dir" sudo chmod "$mode" "$dir"
	fi
done
cleanup_btrfs_top

if $subvols_changed; then
	run_logged "btrfs quota rescan" sudo btrfs quota rescan -w /
fi

# The docker group is root-equivalent: anyone in it can bind-mount the whole
# filesystem into a container and write to it as root. Worth stating rather than
# discovering.
if id -nG "$BUNNY_USER" | grep -qw docker; then
	info "$BUNNY_USER is in the docker group"
else
	run_logged "Adding $BUNNY_USER to the docker group" \
		sudo usermod -aG docker "$BUNNY_USER"
	warn "Group membership takes effect at the next login"
fi

# docker.socket, not docker.service: socket activation means dockerd is not
# resident until something actually speaks to it.
if systemctl is-enabled --quiet docker.socket 2>/dev/null; then
	info "docker.socket already enabled"
else
	run_logged "Enable docker.socket" sudo systemctl enable --now docker.socket
fi

for entry in "${DOCKER_SUBVOLS[@]}"; do
	IFS=: read -r subvol dir _ <<<"$entry"
	if ! subvol_mounted "$subvol" "$dir"; then
		error "$dir is not mounted from $subvol after configuration"
		return 1
	fi
done
success "Docker storage on its own subvolumes, outside root snapshots"
