#!/usr/bin/env bash
# 4.3 — terminal spawn re-verification + kitty decomposition micro-measurements.
# Run on arch-bunny AFTER the terminals are installed and the box freshly
# rebooted. Re-verifies benchmarks/3.7's spawn ordering with the raw-socket
# instrument (3.7 used spawn-to-shell-running; this measures window-mapped —
# different milestone, ordering is the claim under test). Confounds vs 3.7,
# stated: mainline kernel (3.7 ran zen), fresh install, different instrument.
set -Eeuo pipefail
out=~/log/4.3.terminal-rerun.log
exec > >(tee "$out") 2>&1
echo "=== 4.3 terminal rerun $(date -Is) ==="
uptime

echo "--- context: gpu modules + dri nodes (kitty is a GPU terminal) ---"
lsmod | grep -E '^(nouveau|i915)' || true
ls -la /dev/dri/ | grep -v '^total'

echo "--- exec floors (10x each, bash time builtin, warm) ---"
for cmd in "kitty --version" "foot --version" "alacritty --version" "ghostty --version"; do
  # first call warms, next 3 recorded
  $cmd >/dev/null 2>&1 || true
  for i in 1 2 3; do
    TIMEFORMAT="floor ${cmd%% *} run$i %R s"
    time $cmd >/dev/null 2>&1 || true
  done
done

echo "--- fontconfig: Fragment Mono match time ---"
for i in 1 2 3; do TIMEFORMAT="fc-match run$i %R s"; time fc-match "Fragment Mono" >/dev/null; done

echo "--- login-shell cost incl. vapoursynth profile.d (row 71 fresh number) ---"
for i in 1 2 3; do TIMEFORMAT="bash-lc run$i %R s"; time bash -lc true; done
pacman -Qi vapoursynth | grep -E '^(Required By)'
pactree -r ffmpeg 2>/dev/null | head -8 || pacman -Qi ffmpeg | grep 'Required By'

echo "--- spawnbench: all terminals + fuzzel, n=10 ---"
python3 ~/arch-install/spawnbench.py 10 kitty,kitty-noconf,foot,alacritty,ghostty,fuzzel

echo "--- kitty PSS while open (3.7 used RSS, against the later PSS rule) ---"
NIRI_SOCKET=$(ls /run/user/1000/niri*.sock | head -1); export NIRI_SOCKET
niri msg action spawn -- kitty; sleep 3
for t in kitty foot alacritty; do
  pid=$(pgrep -x -n $t || true)
  if [[ -n $pid ]]; then sudo awk -v t=$t '/^Pss:/ {printf "%s PSS_KB %s\n", t, $2}' /proc/$pid/smaps_rollup; fi
done
echo "--- C5: kitty graphics protocol on the fresh install ---"
kitty +kitten icat --detect-support 2>&1 && echo "icat: SUPPORTED (exit 0)" || echo "icat probe exit $? (informational only: real check must run inside a kitty tty; C5 proof stays with the jupyter phase)"
pkill -x -TERM kitty || true; pkill -x -TERM foot || true; pkill -x -TERM alacritty || true

echo "--- niri.service desktop-ready times for past boots (journal mine) ---"
journalctl --user --list-boots --no-pager 2>/dev/null | tail -6 || true
for b in 0 -1 -2 -3; do
  ts=$(journalctl --user -b $b -u niri.service --no-pager -o short-monotonic 2>/dev/null | grep -m1 'Started' || true)
  echo "boot $b: $ts"
done

echo "=== 4.3 complete ==="
