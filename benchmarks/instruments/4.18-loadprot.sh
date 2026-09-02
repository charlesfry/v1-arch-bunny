#!/usr/bin/env bash
set -Eeuo pipefail
LOG="$HOME/log-${0##*/}.log"
exec > >(tee "$LOG") 2>&1

# t-loadprot.sh — the load-protection row's premise, tested:
# does a CPUWeight-capped hog keep interactive latency near baseline while
# an unweighted hog (a "training run") inflates it? Instrument: spawnbench
# kitty spawn→window-mapped, n=5 per condition, same session.
# Conditions: A idle baseline; B full-core hog, default weight;
# C same hog, CPUWeight=1. Hog is bash busy-loops × nproc in a transient
# user unit — dies with `systemctl --user stop`, nothing persists.

BENCH="$HOME/t-spawnbench.py"
# shellcheck disable=SC2016  # deliberate: must expand inside the hog's own bash, not here
HOGCMD='for i in $(seq "$(nproc)"); do (while :; do :; done) & done; wait'

hog_start() { # $1 unit name, extra props after
	local unit=$1
	shift
	systemd-run --user --collect --unit="$unit" "$@" bash -c "$HOGCMD" >/dev/null 2>&1
	sleep 3 # let load ramp
}
hog_stop() {
	systemctl --user stop "$1" >/dev/null 2>&1 || true
	sleep 2
}

echo "=== context $(date -Is) nproc=$(nproc)"
uptime

echo "--- A: idle baseline"
python3 "$BENCH" 5 kitty

echo "--- B: hog at default CPUWeight (100)"
hog_start t-hog-default
uptime
python3 "$BENCH" 5 kitty
hog_stop t-hog-default

echo "--- C: hog at CPUWeight=1"
hog_start t-hog-weighted -p CPUWeight=1
uptime
python3 "$BENCH" 5 kitty
hog_stop t-hog-weighted

echo "--- post: confirm hogs gone"
pgrep -c bash || true
uptime
echo "DONE $(date -Is)"
