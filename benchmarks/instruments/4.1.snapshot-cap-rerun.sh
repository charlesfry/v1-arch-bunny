#!/usr/bin/env bash
# 4.1.snapshot-cap-rerun — DA round 1 rejected the first canary (floor/space ambiguity).
# This rerun decouples them: NUMBER_LIMIT floor set to 0, SPACE_LIMIT stays at the
# PRODUCTION value (0.08 = ~19.93 GiB of the 249 GiB fs). Pass conditions, stated first:
#  P1 space-driven stop: cleanup deletes oldest snapshots until 1/0 exclusive < limit,
#     then STOPS while >0 number snapshots remain (floor=0 cannot explain stopping).
#  P2 real bytes: 'Free (estimated)' from btrfs fi usage rises by ~the deleted size.
#  P3 FREE_LIMIT fires: with FREE_LIMIT=0.999 (unsatisfiable), cleanup deletes ALL
#     remaining number snapshots and reports nothing left to do.
#  P4 production path: the snap-pac pre/post pair from the desktop install (cleanup=number)
#     shows parent 1/0 after prepareQuota, without any manual assign.
set -Eeuo pipefail
log() { printf '\n== %s ==\n' "$*"; }

free_est() { btrfs filesystem usage -b / 2>/dev/null | awk '/Free \(estimated\)/ {print $3; exit}'; }

log "uptime (DA rule: record load)"; uptime
log "config before"; grep -E '^(QGROUP|SPACE_LIMIT|FREE_LIMIT|NUMBER_LIMIT|NUMBER_LIMIT_IMPORTANT|NUMBER_MIN_AGE|TIMELINE_CREATE)=' /etc/snapper/configs/root

log "TEST CONFIG: floor 0, min-age 0 (SPACE_LIMIT untouched at production 0.08)"
snapper -c root set-config 'NUMBER_LIMIT=0-15' 'NUMBER_LIMIT_IMPORTANT=0-5' 'NUMBER_MIN_AGE=0'

log "P4 evidence: qgroup membership of snap-pac snapshots BEFORE any manual action"
snapper list
btrfs qgroup show -p / | tail -8

log "creating 3 canaries pinning ~22 GiB total (production limit is ~19.93 GiB)"
for i in 1 2 3; do
  sz=7; [[ $i == 3 ]] && sz=8
  time dd if=/dev/urandom of=/root/canary-blob bs=1M count=$((sz*1024)) status=none
  sync
  snapper create -c number -d "cap-rerun-c$i (~${sz}GiB)"
  rm /root/canary-blob
done
time btrfs quota rescan -w /
sync

log "state before cleanup"
snapper list
btrfs qgroup show -p / | tail -10
F0=$(free_est); echo "free_estimated_bytes=$F0"

log "P1: snapper cleanup number @ SPACE_LIMIT=0.08, floor=0"
time snapper cleanup number
snapper list
btrfs qgroup show -p / | tail -8

log "P2: reclaimed bytes check (after subvolume sync)"
time btrfs subvolume sync / >/dev/null 2>&1 || true
btrfs quota rescan -w / >/dev/null 2>&1 || true
F1=$(free_est); echo "free_estimated_bytes=$F1"; echo "delta_gib=$(( (F1-F0)/1024/1024/1024 ))"

log "P3: FREE_LIMIT path — set unsatisfiable FREE_LIMIT=0.999, cleanup again"
snapper -c root set-config 'FREE_LIMIT=0.999'
time snapper cleanup number
snapper list
btrfs subvolume sync / >/dev/null 2>&1 || true
F2=$(free_est); echo "free_estimated_bytes=$F2"; echo "delta_gib=$(( (F2-F1)/1024/1024/1024 ))"

log "restore production config (floor stays 0 pending author ratification — flagged)"
snapper -c root set-config 'FREE_LIMIT=0.2' 'NUMBER_MIN_AGE=1800'
grep -E '^(QGROUP|SPACE_LIMIT|FREE_LIMIT|NUMBER_LIMIT|NUMBER_LIMIT_IMPORTANT|NUMBER_MIN_AGE|TIMELINE_CREATE)=' /etc/snapper/configs/root

log "final state"; snapper list; btrfs qgroup show -p / | tail -6; uptime
echo "4.1 rerun complete"
