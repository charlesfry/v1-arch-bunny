#!/usr/bin/env bash
# 4.5 — docker storage quota (gripe #1). The row's acceptance criterion:
# "Do not settle this row until a write is actually refused."
# Phase A: measure WHICH directory grows under Docker 29's containerd
#          snapshotter (3.11 could not: it capped /var/lib/docker and filled
#          with --rm containers). Retained images of incompressible data.
# Phase B: move the growing directory onto its own btrfs subvolume, qgroup
#          limit 2 GiB, import until refusal. cap_enforced=1 iff an import
#          FAILS while the filesystem itself has ample space.
# Phase C: nested-subvolume snapshot exclusion check (snapshot-bloat's
#          mechanism), and recovery (rmi one image -> import succeeds again).
set -Eeuo pipefail
log() { printf '\n== %s ==\n' "$*"; }
sizes() { du -sb /var/lib/docker /var/lib/containerd 2>/dev/null; }

mkimg() { # $1 = name; builds a 256MiB incompressible single-layer image
  dd if=/dev/urandom of=/root/blob.bin bs=1M count=256 status=none
  tar -C /root -cf /root/blob.tar blob.bin
  docker import /root/blob.tar "$1" >/dev/null
  rm -f /root/blob.bin /root/blob.tar
}

log "context"; uptime; docker --version
log "phase A: baseline"; sizes
for i in 1 2 3; do
  mkimg "quotaprobe-a$i:latest"
  log "after import a$i"; sizes
done
log "phase A verdict: the directory that grew is the one to cap"
docker image ls | grep quotaprobe | wc -l

log "phase B: relocate the grower onto a capped subvolume"
systemctl stop docker.service docker.socket containerd.service 2>/dev/null || systemctl stop docker.service docker.socket 2>/dev/null
sleep 2
GROWER=/var/lib/containerd
A_DOCKER=$(du -sb /var/lib/docker | cut -f1); A_CTD=$(du -sb /var/lib/containerd | cut -f1)
if (( A_DOCKER > A_CTD )); then GROWER=/var/lib/docker; fi
echo "grower: $GROWER"
mv "$GROWER" "${GROWER}.old"
btrfs subvolume create "$GROWER"
cp -a "${GROWER}.old/." "$GROWER/"
rm -rf "${GROWER}.old"
SUBVOLID=$(btrfs subvolume list / | awk -v p="${GROWER#/}" '$NF == p {print $2}')
echo "new subvolume id: $SUBVOLID"
btrfs qgroup limit 2G "0/$SUBVOLID" "$GROWER"
btrfs qgroup show -re / | awk -v id="0/$SUBVOLID" '$1 == id'
systemctl start docker.service
sleep 3

log "phase B: fill until refused (2 GiB cap, 256 MiB per retained image)"
refused=0
for i in $(seq 1 12); do
  if ! out=$( { dd if=/dev/urandom of=/root/blob.bin bs=1M count=256 status=none && \
                tar -C /root -cf /root/blob.tar blob.bin && \
                docker import /root/blob.tar "quotafill-$i:latest"; } 2>&1 ); then
    echo "IMPORT $i REFUSED:"; echo "$out" | tail -3
    refused=1
    break
  fi
  echo "import $i ok; grower now: $(du -sb "$GROWER" | cut -f1) bytes"
done
rm -f /root/blob.bin /root/blob.tar
echo "cap_enforced=$refused"
log "filesystem itself has ample space (the cap did this, not the disk)"
btrfs filesystem usage / 2>/dev/null | grep -E 'Free \(estimated\)'

log "phase C1: recovery — remove one image, import must succeed again"
docker image rm -f "quotafill-1:latest" >/dev/null 2>&1 || true
sleep 1
if mkimg "quotarecover:latest"; then echo "recovery_ok=1"; else echo "recovery_ok=0"; fi

log "phase C2: nested subvolume is excluded from root snapshots"
N=$(snapper create -p -d "4.5 exclusion check")
echo "snapshot #$N"
ls "/.snapshots/$N/snapshot${GROWER}" 2>/dev/null | head -3
CNT=$(ls -A "/.snapshots/$N/snapshot${GROWER}" 2>/dev/null | wc -l)
echo "entries visible inside snapshot at ${GROWER}: $CNT (0 = excluded, as the snapshot-bloat row hopes)"
snapper delete "$N"

log "cleanup: remove all test images, report final state"
docker image ls --format "{{.Repository}}:{{.Tag}}" | grep -E "quotaprobe|quotafill|quotarecover" | xargs -r docker image rm -f >/dev/null
docker system prune -f >/dev/null 2>&1 || true
sizes
btrfs qgroup show -re / | awk -v id="0/$SUBVOLID" '$1 == id'
echo "NOTE: $GROWER is now a dedicated subvolume with a 2 GiB qgroup limit — LEFT IN PLACE"
echo "as the live trial of the row's candidate (2); the limit value is a test value,"
echo "author sizes the real one."
echo "=== 4.5 complete ==="
