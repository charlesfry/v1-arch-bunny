#!/usr/bin/env bash
# 4.14b — DA-demanded discriminating probe. Runs ON bunne-test inside the session.
# Boot C: the boot's FIRST kitty spawned LATE (~420 s uptime) — ordinal-vs-uptime.
# Boot D: first kitty early (~60 s) with Pss_Anon/File/Shmem split, then W2 with split
#         — artifact-vs-real for both the adopted figure and the W2 anomaly.
# Argument: C or D (which arm this boot runs).
set -Eeuo pipefail
ARM="${1:?arm C or D}"
NIRI_SOCKET="$(ls /run/user/1000/niri*.sock)"
export NIRI_SOCKET
grep -q '^NAME="Arch' /etc/os-release || { echo "ABORT: not Arch"; exit 1; }
spawn() { python3 -c 'import json,socket,os;s=socket.socket(socket.AF_UNIX);s.connect(os.environ["NIRI_SOCKET"]);s.sendall((json.dumps({"Action":{"Spawn":{"command":["kitty"]}}})+chr(10)).encode())'; }
kpid() { python3 -c 'import json,socket,os;s=socket.socket(socket.AF_UNIX);s.connect(os.environ["NIRI_SOCKET"]);s.sendall((json.dumps("Windows")+chr(10)).encode());r=json.loads(s.makefile().readline());ws=[w for w in r["Ok"]["Windows"] if w["app_id"]=="kitty"];print(ws[-1]["pid"] if ws else "")'; }
split() { awk '/^Pss:/{t=$2} /^Pss_Anon:/{a=$2} /^Pss_File:/{f=$2} /^Pss_Shmem:/{sh=$2} END{printf "pss_kb=%s anon_kb=%s file_kb=%s shmem_kb=%s", t, a, f, sh}' "/proc/$1/smaps_rollup"; }
hdr() { echo "BOOT-$ARM $(date -Is) id=$(cat /proc/sys/kernel/random/boot_id) uptime=$(cut -d' ' -f1 /proc/uptime)s load=$(cut -d' ' -f1 /proc/loadavg) ac=$(cat /sys/class/power_supply/AC*/online 2>/dev/null || echo '?')"; }
if [ "$ARM" = C ]; then
  # wait until ~420 s uptime with NO kitty ever spawned this boot
  while [ "$(cut -d. -f1 /proc/uptime)" -lt 420 ]; do sleep 5; done
  hdr
  spawn; sleep 5; p=$(kpid); [ -n "$p" ] || { echo ABORT-no-pid; exit 1; }
  echo "C-W1late age=5s $(split "$p") pid=$p"
  sleep 55;  echo "C-W1late age=60s $(split "$p")"
  sleep 60;  echo "C-W1late age=120s $(split "$p")"
  kill "$p"
else
  hdr
  spawn; sleep 5; p=$(kpid); [ -n "$p" ] || { echo ABORT-no-pid; exit 1; }
  echo "D-W1 age=5s $(split "$p") pid=$p"
  sleep 115; echo "D-W1 age=120s $(split "$p")"
  kill "$p"; sleep 2
  spawn; sleep 5; q=$(kpid); [ -n "$q" ] || { echo ABORT-no-pid; exit 1; }
  echo "D-W2 age=5s $(split "$q") pid=$q"
  sleep 115; echo "D-W2 age=120s $(split "$q")"
  kill "$q"
fi
