#!/usr/bin/env bash
set -Eeuo pipefail
LOG="$HOME/log-${0##*/}.log"
exec > >(tee -a "$LOG") 2>&1

# t-greetd-measure.sh — one sample per boot for the display-manager row:
# boot timings, greetd's real resident cost (the row's unsourced "~2 MB"),
# session shape, polkit agent health, and an unlocked spawn canary.
# Appends to its log; run once per boot in both configurations.

echo
echo "=== boot sample $(date -Is) boot_id=$(cat /proc/sys/kernel/random/boot_id)"
echo "login path: $(systemctl is-enabled greetd 2>/dev/null || true) (greetd) / getty-drop-in present: $(test -f /etc/systemd/system/getty@tty1.service.d/autologin.conf && echo yes || echo no)"
systemd-analyze | head -1
systemd-analyze critical-chain graphical.target 2>/dev/null | sed -n '3,5p'

echo "--- residents"
for pid in $(pgrep -x greetd || true); do
	echo "greetd pid $pid: PSS $(sudo awk '/^Pss:/{print $2 " kB"}' "/proc/$pid/smaps_rollup") rss $(awk '/VmRSS/{print $2 " kB"}' "/proc/$pid/status")"
done
pgrep -x greetd >/dev/null || echo "greetd: not running"

echo "--- session shape"
loginctl list-sessions --no-pager 2>/dev/null | head -6
pgrep -af mate-polkit | head -2 || echo "mate-polkit: NOT running"
journalctl -b --no-pager 2>/dev/null | awk '/Registered Authentication Agent/' | tail -2

echo "--- niri + spawn canary (must pass on an unlocked fresh session)"
pgrep -ax niri | head -1 || echo "niri: NOT running"
NIRI_SOCKET=$(compgen -G "/run/user/1000/niri.wayland-*.sock" | head -1)
export NIRI_SOCKET
rm -f "$HOME/niri-canary-boot"
niri msg action spawn -- touch "$HOME/niri-canary-boot" 2>/dev/null || echo "IPC spawn errored"
sleep 1
test -f "$HOME/niri-canary-boot" && echo "spawn canary: PASS" || echo "spawn canary: FAIL"
echo "=== sample done"
