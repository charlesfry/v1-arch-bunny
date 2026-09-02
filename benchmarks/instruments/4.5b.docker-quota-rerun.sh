#!/usr/bin/env bash
# 4.5b — DA-demanded rerun of the docker-quota enforcement claims, fully tee'd.
# Answers da round-1 points: raw-backed refusal (n=2 on docker path), the real
# install.sh recipe on FRESH subvolumes (n=2, no cp -a migration), logged wedge
# + recovery + post-recovery consistency check, and the trap-7 question: does a
# routine snapper snapshot re-mark qgroups inconsistent and disarm the cap?
set -Eeuo pipefail
log() { printf '\n== %s ==\n' "$*"; }
qg() { btrfs qgroup show -re / | awk -v id="$1" '$1 == id'; }
flag() { dmesg | grep -i "qgroup" | tail -2; }

log "state now (post 4.5 + recovery): consistency + 0/271"
qg 0/271; flag

log "TRAP-7 TEST: snapper snapshot, then is the cap still armed?"
N=$(snapper create -p -d "4.5b trap-7 probe")
echo "created snapshot #$N"
flag
echo "-- import must still be capped: current use + 4x256MiB imports would cross 2G --"
systemctl start docker.socket 2>/dev/null || true
ok=0; refused=0
for i in 1 2 3 4 5 6; do
  if ! out=$( { dd if=/dev/urandom of=/root/b.bin bs=1M count=256 status=none && tar -C /root -cf /root/b.tar b.bin && docker import /root/b.tar "t7-$i:latest"; } 2>&1 ); then
    echo "t7 import $i REFUSED: $(echo "$out" | tail -1 | cut -c1-140)"; refused=1; break
  fi
  ok=$((ok+1)); echo "t7 import $i ok; qgroup: $(btrfs qgroup show -re / | awk '$1=="0/271" {print $2, "of", $4}')"
done
echo "trap7_cap_still_armed=$refused (after $ok imports)"
snapper delete "$N"

log "docker-path recovery round 2, fully logged"
docker image ls --format "{{.Repository}}:{{.Tag}}" | grep '^t7-' | xargs -r docker image rm -f 2>&1 | tail -2 || true
echo "-- if deletes were refused (wedge), bump-clean-relimit: --"
if docker image ls --format "{{.Repository}}:{{.Tag}}" | grep -q '^t7-'; then
  btrfs qgroup limit 4G 0/271 /var/lib/containerd
  docker image ls --format "{{.Repository}}:{{.Tag}}" | grep '^t7-' | xargs -r docker image rm -f && echo "wedge recovery: deletes ok at 4G"
  docker system prune -f >/dev/null 2>&1 || true
  btrfs qgroup limit 2G 0/271 /var/lib/containerd
  echo "relimited to 2G"
fi
docker system prune -f >/dev/null 2>&1 || true
btrfs quota rescan -w / >/dev/null 2>&1
log "post-recovery consistency + health (import AND delete under the cap)"
qg 0/271; flag
dd if=/dev/urandom of=/root/b.bin bs=1M count=64 status=none && tar -C /root -cf /root/b.tar b.bin
docker import /root/b.tar health2:latest >/dev/null && echo "post-recovery import ok"
docker image rm -f health2:latest >/dev/null && echo "post-recovery delete ok"
rm -f /root/b.bin /root/b.tar

log "PRODUCTION RECIPE on FRESH subvolumes (no migration), n=2"
for t in 1 2; do
  SV=/root/quota-recipe-test-$t
  btrfs subvolume create "$SV"
  btrfs quota rescan -w /
  ID=$(btrfs subvolume list / | awk -v p="${SV#/}" '$NF == p {print $2}')
  btrfs qgroup limit 512M "0/$ID" "$SV"
  echo "-- fresh subvol $SV (0/$ID), limit 512M; consistency: --"; flag
  refused=0
  for i in 1 2 3 4 5 6 7 8; do
    if ! dd if=/dev/urandom of="$SV/f$i" bs=1M count=128 conv=fsync status=none 2>/tmp/dderr; then
      echo "write $i REFUSED: $(tail -1 /tmp/dderr | cut -c1-120)"; refused=1; break
    fi
    echo "write $i ok; qgroup: $(btrfs qgroup show -re / | awk -v id="0/$ID" '$1==id {print $2, "of", $4}')"
  done
  echo "recipe_test_${t}_cap_enforced=$refused"
  btrfs subvolume delete "$SV" >/dev/null
done
btrfs quota rescan -w / >/dev/null 2>&1

log "final state"
qg 0/271; flag
du -sb /var/lib/containerd
echo "=== 4.5b complete ==="
