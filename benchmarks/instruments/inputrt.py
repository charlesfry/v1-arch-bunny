#!/usr/bin/env python3
"""inputrt — terminal input-loop round-trip: write ESC[6n (DSR cursor-position
query) to the tty, time until the terminal's reply arrives. This exercises the
terminal's input/parse/reply loop (3.7's "input-rt" column). NOT
keystroke-to-photon (no compositor/present in the loop).

Runs INSIDE the terminal under test (spawn as: kitty -e python3 inputrt.py
<label>). Appends JSON lines to ~/log/inputrt.jsonl and exits.
"""
import json
import os
import sys
import termios
import time
import tty

label = sys.argv[1] if len(sys.argv) > 1 else "unknown"
n = int(sys.argv[2]) if len(sys.argv) > 2 else 50

fd = sys.stdin.fileno()
old = termios.tcgetattr(fd)
results = []
try:
    tty.setraw(fd)
    # warmup / drain
    os.write(1, b"\x1b[6n")
    time.sleep(0.05)
    os.read(fd, 64)
    for i in range(n):
        t0 = time.perf_counter()
        os.write(1, b"\x1b[6n")
        buf = b""
        while not buf.endswith(b"R"):
            buf += os.read(fd, 32)
        dt = (time.perf_counter() - t0) * 1000.0
        results.append(dt)
        time.sleep(0.01)
finally:
    termios.tcsetattr(fd, termios.TCSADRAIN, old)

results_sorted = sorted(results)
out = {
    "label": label,
    "kernel": os.uname().release,
    "n": n,
    "min_ms": round(results_sorted[0], 3),
    "median_ms": round(results_sorted[n // 2], 3),
    "p90_ms": round(results_sorted[int(n * 0.9)], 3),
    "max_ms": round(results_sorted[-1], 3),
    "load1": round(os.getloadavg()[0], 2),
}
with open(os.path.expanduser("~/log/inputrt.jsonl"), "a") as f:
    f.write(json.dumps(out) + "\n")
