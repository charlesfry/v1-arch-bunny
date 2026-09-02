#!/usr/bin/env python3
"""spawnbench-hypr — spawn -> on-screen latency via raw Hyprland sockets.

Hyprland port of spawnbench.py (v2), for the Omarchy desktop (4090 box):
  - t0 = perf_counter immediately before writing `dispatch exec <cmd>` to
    Hyprland's command socket (.socket.sock) — the same code path as a
    keybind's exec.
  - t1 = the `openwindow>>...,<class>,...` event arriving on the event
    socket (.socket2.sock), connected BEFORE the spawn so nothing is missed.
  - teardown: `dispatch closewindow class:^(<class>)$`, confirmed by the
    closewindow event, before the next run. No -9 anywhere.
  - run 0 is the cold run — labeled, never silently discarded.

Output: one JSON line per run + a summary line, load1 per run — the same
shape as spawnbench.py so cross-compositor tables read alike. Note the
milestone is Hyprland's openwindow event vs niri's window-in-IPC-list;
treat cross-compositor deltas as coarse until the two milestones are
shown equivalent.
"""
import json
import os
import socket
import sys
import time

sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
if not sig:
    sys.exit("HYPRLAND_INSTANCE_SIGNATURE not set — run inside the Hyprland session")
base = os.path.join(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"), "hypr", sig)


def cmd(text):
    s = socket.socket(socket.AF_UNIX)
    s.settimeout(2.0)
    s.connect(os.path.join(base, ".socket.sock"))
    s.sendall(text.encode())
    r = s.recv(4096).decode()
    s.close()
    return r


def bench(app, execline, klass, n):
    times = []
    ev = socket.socket(socket.AF_UNIX)
    ev.connect(os.path.join(base, ".socket2.sock"))
    ev.settimeout(10.0)
    buf = b""

    def wait_event(name, match):
        # openwindow>>ADDR,WS,CLASS,TITLE ; closewindow>>ADDR (no class!)
        nonlocal buf
        deadline = time.perf_counter() + 10.0
        while time.perf_counter() < deadline:
            nl = buf.find(b"\n")
            if nl == -1:
                buf += ev.recv(4096)
                continue
            line, buf = buf[:nl], buf[nl + 1:]
            f = line.decode(errors="replace")
            if not f.startswith(name + ">>"):
                continue
            payload = f.split(">>", 1)[1]
            if name == "openwindow":
                fields = payload.split(",", 3)
                if len(fields) >= 3 and fields[2] == match:
                    return time.perf_counter(), fields[0]
            elif payload.split(",", 1)[0] == match:
                return time.perf_counter(), match
        sys.exit(f"{app}: no {name} event within 10 s — failing loudly")

    for i in range(n):
        if f"class: {klass}" in cmd("j/clients") or f'"class": "{klass}"' in cmd("j/clients"):
            sys.exit(f"{app}: already present before run {i} — dirty state, aborting")
        t0 = time.perf_counter()
        r = cmd(f"dispatch exec {execline}")
        if "ok" not in r:
            sys.exit(f"{app}: dispatch refused: {r!r}")
        t1, addr = wait_event("openwindow", klass)
        ms = (t1 - t0) * 1000.0
        times.append(ms)
        print(json.dumps({"app": app, "run": i, "ms": round(ms, 1),
                          "load1": round(os.getloadavg()[0], 2),
                          "cold": i == 0}), flush=True)
        cmd(f"dispatch closewindow address:0x{addr}")
        wait_event("closewindow", addr)
        time.sleep(0.5)
    ev.close()
    warm = sorted(times[1:])
    print(json.dumps({"app": app, "summary": True, "n": n,
                      "cold_ms": round(times[0], 1),
                      "warm_min": round(warm[0], 1),
                      "warm_median": round(warm[len(warm) // 2], 1),
                      "warm_max": round(warm[-1], 1)}), flush=True)


APPS = {
    "kitty": ("kitty", "kitty"),
    # glvnd pinned to mesa only — on an NVIDIA-primary box this removes the
    # MESA ICD instead; the meaningful pin here is nvidia-only:
    "kitty-nvidiaonly": (
        "env __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json kitty",
        "kitty"),
}

n = int(sys.argv[1]) if len(sys.argv) > 1 else 10
apps = (sys.argv[2] if len(sys.argv) > 2 else "kitty").split(",")
print(json.dumps({"meta": True, "compositor": "hyprland", "sig": sig, "n": n,
                  "apps": apps, "wallclock": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
                  "load1_start": round(os.getloadavg()[0], 2)}), flush=True)
for name in apps:
    execline, klass = APPS[name]
    bench(name, execline, klass, n)
