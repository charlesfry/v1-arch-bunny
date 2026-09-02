#!/usr/bin/env bash
# boot-battery — identical per-boot measurement battery for the Arch/NixOS bake-off.
# Run as bunne a fixed interval after boot. Args: <label> (e.g. arch-boot2)
set -Eeuo pipefail
label=${1:?usage: boot-battery.sh <label>}
out=~/log/battery.$label.log
exec > >(tee "$out") 2>&1

echo "=== boot battery: $label $(date -Is) ==="
echo "--- settle: waiting until 60s of uptime ---"
up=$(cut -d. -f1 /proc/uptime)
(( up < 60 )) && sleep $((60 - up))
uptime

echo "--- systemd-analyze ---"
systemd-analyze
systemd-analyze critical-chain --no-pager 2>/dev/null | head -25 || true
echo "--- blame top 15 ---"
systemd-analyze blame --no-pager 2>/dev/null | head -15 || true

echo "--- PSS sums, 3 samples 20s apart ---"
for i in 1 2 3; do
  sudo bash ~/arch-install/pss-sum.sh
  echo "--sample $i done--"
  [[ $i -lt 3 ]] && sleep 20
done

echo "--- spawnbench n=10 ---"
python3 ~/arch-install/spawnbench.py 10

echo "=== battery $label complete ==="
