#!/usr/bin/env bash
set -Eeuo pipefail
LOG="$HOME/log-${0##*/}.log"
exec > >(tee "$LOG") 2>&1

# t-oomd.sh — oom-protection row's canary: does systemd-oomd kill a runaway
# memory hog BEFORE the kernel OOM killer / a thrash-death, with the session
# staying reachable? Canary shape: designed to fail loudly if the mechanism
# does nothing (hog hits its own RuntimeMaxSec and dies by timeout = FAIL).
#
# Box facts this depends on: 15.8 GiB RAM, 7.7 GiB zram swap (compressed —
# hence the hog allocates os.urandom, which zram cannot compress away).
# Config (test-rig change, recorded): systemd-oomd enabled; swap-kill on
# -.slice and user@.service; pressure-kill on user@.service.

echo "=== context $(date -Is)"
free -m | head -3
echo "PSI present: $(test -r /proc/pressure/memory && echo yes || echo NO)"

echo "--- config drop-ins + enable oomd"
sudo mkdir -p /etc/systemd/system/user@.service.d /etc/systemd/system/-.slice.d
printf '[Service]\nManagedOOMMemoryPressure=kill\nManagedOOMSwap=kill\n' |
	sudo tee /etc/systemd/system/user@.service.d/10-oomd-test.conf >/dev/null
printf '[Slice]\nManagedOOMSwap=kill\n' |
	sudo tee /etc/systemd/system/-.slice.d/10-oomd-test.conf >/dev/null
sudo systemctl daemon-reload
sudo systemctl enable --now systemd-oomd.service
sleep 1
oomctl | head -30

echo "--- launch hog (256 MiB urandom chunks, 0.4 s apart, 300 s hard cap)"
T0=$(date +%s)
systemd-run --user --collect --unit=t-memhog -p RuntimeMaxSec=300 \
	python3 -c '
import os, time, sys
buf = []
i = 0
while True:
    buf.append(os.urandom(256 * 1024 * 1024))
    i += 1
    print(f"chunk {i} ({i*256} MiB held)", flush=True)
    time.sleep(0.4)
'

echo "--- watch: hog unit state + swap, every 5 s (responsiveness probe = this loop itself)"
VERDICT=timeout
for _ in $(seq 70); do
	sleep 5
	NOW=$(($(date +%s) - T0))
	SW=$(free -m | awk '/Swap/{print $3"/"$2" MiB"}')
	ST=$(systemctl --user is-active t-memhog.service 2>/dev/null || true)
	echo "t+${NOW}s swap=$SW hog=$ST"
	if [[ $ST != active ]]; then
		RES=$(systemctl --user show t-memhog.service -p Result --value 2>/dev/null || true)
		echo "hog ended: Result=$RES at t+${NOW}s"
		VERDICT=$RES
		break
	fi
done

echo "--- evidence"
journalctl -u systemd-oomd.service --since "-8 min" --no-pager | tail -6
journalctl --user -u t-memhog.service --since "-8 min" --no-pager | tail -4
sudo dmesg -T | awk '/Out of memory|oom-kill|oom_reaper/' | tail -4 || true
free -m | head -3
echo "VERDICT: $VERDICT (oom-kill = systemd-oomd did it; timeout = mechanism did nothing; exit-code/killed = inspect)"
echo "DONE $(date -Is)"
