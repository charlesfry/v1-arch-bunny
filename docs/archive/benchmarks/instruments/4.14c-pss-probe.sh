#!/usr/bin/env bash
# 4.14c — DA-round-2-demanded probes. Runs ON bunne-test inside the session.
# Arm E: W1 at spawn-uptime 60±10 s, ASSERTED in code, with anon/file split (n>=3 boots).
# Arm F: drop_caches at ~420 s idle, THEN spawn first window with split — the causal
#        counterfactual for page-cache warmth; also deposits the idle window's journal.
set -Eeuo pipefail
ARM="${1:?arm E or F}"
NIRI_SOCKET="$(ls /run/user/1000/niri*.sock)"
export NIRI_SOCKET
grep -q '^NAME="Arch' /etc/os-release || { echo "ABORT: not Arch"; exit 1; }
spawn() { python3 -c 'import json,socket,os;s=socket.socket(socket.AF_UNIX);s.connect(os.environ["NIRI_SOCKET"]);s.sendall((json.dumps({"Action":{"Spawn":{"command":["kitty"]}}})+chr(10)).encode())'; }
kpid() { python3 -c 'import json,socket,os;s=socket.socket(socket.AF_UNIX);s.connect(os.environ["NIRI_SOCKET"]);s.sendall((json.dumps("Windows")+chr(10)).encode());r=json.loads(s.makefile().readline());ws=[w for w in r["Ok"]["Windows"] if w["app_id"]=="kitty"];print(ws[-1]["pid"] if ws else "")'; }
split() { awk '/^Pss:/{t=$2} /^Pss_Anon:/{a=$2} /^Pss_File:/{f=$2} /^Pss_Shmem:/{sh=$2} END{printf "pss_kb=%s anon_kb=%s file_kb=%s shmem_kb=%s", t, a, f, sh}' "/proc/$1/smaps_rollup"; }
up() { cut -d. -f1 /proc/uptime; }
hdr() { echo "BOOT-$ARM $(date -Is) id=$(cat /proc/sys/kernel/random/boot_id) uptime=$(cut -d' ' -f1 /proc/uptime)s load=$(cut -d' ' -f1 /proc/loadavg) ac=$(cat /sys/class/power_supply/AC*/online 2>/dev/null || echo '?')"; }
[ -z "$(kpid)" ] || { echo "ABORT: kitty already present this boot"; exit 1; }
if [ "$ARM" = E ]; then
  U=$(up); [ "$U" -ge 50 ] && [ "$U" -le 70 ] || { echo "ABORT: uptime $U outside 60±10 s"; exit 1; }
  hdr
  spawn; sleep 5; p=$(kpid); [ -n "$p" ] || { echo "ABORT: no pid"; exit 1; }
  echo "E-W1 age=5s $(split "$p") pid=$p spawn_uptime=${U}s"
  sleep 115; echo "E-W1 age=120s $(split "$p")"
  sleep 180; echo "E-W1 age=300s $(split "$p")"
  kill "$p"
else
  while [ "$(up)" -lt 420 ]; do sleep 5; done
  hdr
  echo "F journal of the idle window (what warmed the cache):"
  journalctl -b --no-pager --since "-8 min" | grep -vE "sshd|sudo|pam_" | tail -15 | sed 's/^/F-journal: /'
  sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
  echo "F drop_caches done at uptime=$(cut -d' ' -f1 /proc/uptime)s"
  spawn; sleep 5; p=$(kpid); [ -n "$p" ] || { echo "ABORT: no pid"; exit 1; }
  echo "F-W1postdrop age=5s $(split "$p") pid=$p"
  sleep 115; echo "F-W1postdrop age=120s $(split "$p")"
  kill "$p"
fi
