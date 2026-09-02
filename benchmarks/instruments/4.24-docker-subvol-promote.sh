#!/usr/bin/env bash
# Move the Docker/containerd subvolumes out of @ and up to the btrfs top level,
# so a `@` rollback cannot silently un-cap Docker or drag its data into a snapshot.
# CHOICES.md `docker-storage-quota`, ratified 2026-08-25 (open-questions #17).
set -Eeuo pipefail

UUID=07175cbe-0559-49d6-9163-c9a21863c3f5
TOP=/mnt/btrfs
OPTS='rw,noatime,compress=zstd:1,ssd,space_cache=v2'

echo "== stopping docker ==" >&2
sudo systemctl stop docker.socket docker.service containerd.service 2>/dev/null || true

echo "== mounting top level ==" >&2
sudo mkdir -p "$TOP"
mountpoint -q "$TOP" || sudo mount -o "subvolid=5,$OPTS" "UUID=$UUID" "$TOP"

echo "== promoting subvolumes ==" >&2
# A snapshot of a subvolume IS a subvolume; taking it at the top level moves the
# data without copying a byte.
#
# GUARD, and it is the whole reason this is a script and not two commands:
# `btrfs subvolume snapshot` DOES NOT RECURSE into nested subvolumes, and
# docker's btrfs storage driver creates one subvolume per image layer. On a
# machine with images, an unguarded run produces a `@dockervol` that looks
# migrated and contains none of them, then aborts at the delete below with fstab
# still unedited -- a half-migrated Docker on a machine whose whole point is that
# it just works. This box had zero images when the script was first run
# (`docker images` empty, du 176K/400K), which is exactly why the hazard could
# not have shown itself there. Refuse rather than silently lose layers.
for src in "$TOP/@/var/lib/containerd" "$TOP/@/var/lib/docker"; do
	kids=$(sudo btrfs subvolume list -o "$src" | wc -l)
	[ "$kids" -eq 0 ] || {
		echo "REFUSING: $src has $kids nested subvolume(s); a snapshot would not copy them." >&2
		echo "  Stop docker, list them with 'btrfs subvolume list -o', and move the data another way" >&2
		echo "  (send/receive, or cp --reflink=always) before promoting." >&2
		exit 1
	}
done
[ -d "$TOP/@containerd" ] || sudo btrfs subvolume snapshot "$TOP/@/var/lib/containerd" "$TOP/@containerd"
[ -d "$TOP/@dockervol" ] || sudo btrfs subvolume snapshot "$TOP/@/var/lib/docker" "$TOP/@dockervol"

echo "== deleting the nested originals ==" >&2
sudo btrfs subvolume delete "$TOP/@/var/lib/containerd"
sudo btrfs subvolume delete "$TOP/@/var/lib/docker"
sudo mkdir -p "$TOP/@/var/lib/containerd" "$TOP/@/var/lib/docker"

echo "== fstab ==" >&2
sudo cp /etc/fstab /etc/fstab.pre-docker-subvols.bak
for pair in "containerd:/var/lib/containerd" "dockervol:/var/lib/docker"; do
	sub=${pair%%:*}
	dir=${pair##*:}
	grep -q "subvol=/@$sub\b" /etc/fstab || printf '\n# /dev/mapper/archcrypt LABEL=archroot\nUUID=%s\t%s\tbtrfs\t%s,subvol=/@%s\t0 0\n' \
		"$UUID" "$dir" "$OPTS" "$sub" | sudo tee -a /etc/fstab >/dev/null
done

echo "== mounting ==" >&2
sudo systemctl daemon-reload
sudo mount -a
# sudo: these mountpoints are mode 0700 root, and findmnt stats the path first.
sudo findmnt -no SOURCE,TARGET,OPTIONS /var/lib/containerd /var/lib/docker

echo "== re-applying the byte caps ==" >&2
sudo btrfs qgroup limit 100G /var/lib/containerd
sudo btrfs qgroup limit 50G /var/lib/docker
sudo btrfs quota rescan -w /

echo "== restarting docker ==" >&2
sudo systemctl start docker.socket
sudo docker info >/dev/null
sudo btrfs qgroup show -re / | grep -E 'containerd|dockervol|Path'
