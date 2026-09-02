#!/usr/bin/env bash
# 4.16 — kitty anon drift, long run. Closes 4.14's right-censoring: no sample
# existed past age 300 s, so the long-lived anon figure was only ">=54 MB".
# One idle kitty window, smaps_rollup split sampled to age 3 h.
# Helpers copied verbatim from instruments/4.14c-pss-probe.sh for comparability.
set -Eeuo pipefail
DURATION="${1:-10800}" # seconds of window age to cover
NIRI_SOCKET="$(ls /run/user/1000/niri*.sock)"
export NIRI_SOCKET
grep -q '^NAME="Arch' /etc/os-release || { echo "ABORT: not Arch"; exit 1; }
spawn() { python3 -c 'import json,socket,os;s=socket.socket(socket.AF_UNIX);s.connect(os.environ["NIRI_SOCKET"]);s.sendall((json.dumps({"Action":{"Spawn":{"command":["kitty"]}}})+chr(10)).encode())'; }
kpid() { python3 -c 'import json,socket,os;s=socket.socket(socket.AF_UNIX);s.connect(os.environ["NIRI_SOCKET"]);s.sendall((json.dumps("Windows")+chr(10)).encode());r=json.loads(s.makefile().readline());ws=[w for w in r["Ok"]["Windows"] if w["app_id"]=="kitty"];print(ws[-1]["pid"] if ws else "")'; }
split() { awk '/^Pss:/{t=$2} /^Pss_Anon:/{a=$2} /^Pss_File:/{f=$2} /^Pss_Shmem:/{sh=$2} END{printf "pss_kb=%s anon_kb=%s file_kb=%s shmem_kb=%s", t, a, f, sh}' "/proc/$1/smaps_rollup"; }
echo "BOOT-DRIFT $(date -Is) id=$(cat /proc/sys/kernel/random/boot_id) uptime=$(cut -d' ' -f1 /proc/uptime)s load=$(cut -d' ' -f1 /proc/loadavg) ac=$(cat /sys/class/power_supply/AC*/online 2>/dev/null || echo '?')"
[ -z "$(kpid)" ] || { echo "ABORT: kitty already present this boot"; exit 1; }
spawn
sleep 5
p=$(kpid)
[ -n "$p" ] || { echo "ABORT: no pid"; exit 1; }
echo "W1 age=5s $(split "$p") pid=$p spawn_uptime=$(cut -d. -f1 /proc/uptime)s"
age=5
for target in 30 60 120 300; do
  sleep $((target - age)); age=$target
  [ -d "/proc/$p" ] || { echo "ABORT: kitty died at age<${age}s"; exit 1; }
  echo "W1 age=${age}s $(split "$p")"
done
while [ "$age" -lt "$DURATION" ]; do
  sleep 300; age=$((age + 300))
  [ -d "/proc/$p" ] || { echo "ABORT: kitty died at age<${age}s"; exit 1; }
  echo "W1 age=${age}s $(split "$p") load=$(cut -d' ' -f1 /proc/loadavg)"
done
kill "$p"
echo "DONE $(date -Is)"
