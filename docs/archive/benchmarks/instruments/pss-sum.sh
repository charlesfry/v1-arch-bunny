#!/usr/bin/env bash
# pss-sum — total PSS across all processes + top consumers, per project rule
# (sum PSS never RSS). Run as root; smaps_rollup is not readable otherwise.
set -Eeuo pipefail
total=0
declare -A per
for f in /proc/[0-9]*/smaps_rollup; do
  pid=${f#/proc/}
  pid=${pid%/smaps_rollup}
  pss=$(awk '/^Pss:/ {print $2}' "$f" 2>/dev/null) || continue
  [[ -n $pss ]] || continue
  comm=$(cat "/proc/$pid/comm" 2>/dev/null || echo '?')
  total=$((total + pss))
  per[$comm]=$((${per[$comm]:-0} + pss))
done
echo "PSS_TOTAL_KB=$total"
for k in "${!per[@]}"; do echo "${per[$k]} $k"; done | sort -rn | head -20
free -m | sed -n '1,2p'
uptime
