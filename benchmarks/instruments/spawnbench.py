#!/usr/bin/env python3
"""spawnbench — spawn -> on-screen latency via raw niri IPC socket.

One instrument, run identically on Arch and NixOS (same hardware, same niri),
so cross-OS deltas compare like with like — the gap DA rejected in nix-bunne
round 1.7.

Method:
  - t0 = perf_counter immediately before sending the IPC Spawn action
    (the exact same code path as the Mod+T keybind).
  - poll the IPC socket (fresh connection per request, ~0.2-0.5 ms each)
    until the target appears: kitty -> a window with app_id "kitty" in
    "Windows"; fuzzel -> a layer surface with namespace "launcher" in "Layers".
  - teardown: kitty via CloseWindow action; fuzzel via SIGTERM. Wait until
    provably gone before the next run. No -9 anywhere.
  - all runs recorded, run 0 is the post-boot cold run — never discarded
    silently, labeled instead.

Output: one JSON line per run + a summary line. Load avg recorded per run.
"""
import glob
import json
import os
import socket
import subprocess
import sys
import time

sock_path = os.environ.get("NIRI_SOCKET")
if not sock_path:
    cands = glob.glob("/run/user/*/niri*.sock")
    if not cands:
        sys.exit("no niri socket found — is the session up?")
    sock_path = cands[0]


def req(obj):
    s = socket.socket(socket.AF_UNIX)
    s.settimeout(2.0)
    s.connect(sock_path)
    s.sendall((json.dumps(obj) + "\n").encode())
    data = b""
    while not data.endswith(b"\n"):
        chunk = s.recv(1 << 16)
        if not chunk:
            break
        data += chunk
    s.close()
    r = json.loads(data)
    if "Err" in r:
        raise RuntimeError(r["Err"])
    return r["Ok"]


def win_present(app_id):
    for w in req("Windows")["Windows"]:
        if w.get("app_id") == app_id:
            return w["id"]
    return None


def fuzzel_present():
    for l in req("Layers")["Layers"]:
        if l.get("namespace") == "launcher":
            return True
    return None


def win_teardown(procname):
    # SIGTERM, not CloseWindow: the IPC close can arrive ~30ms post-spawn, while
    # the shell is still forking, and trips kitty's confirm-close prompt — a race
    # real usage never hits. TERM is a clean shutdown (no -9).
    # NixOS wraps binaries: the live process is often ".<name>-wrapped".
    subprocess.run(["pkill", "-x", "-TERM", procname], check=False)
    subprocess.run(["pkill", "-x", "-TERM", f".{procname}-wrapped"], check=False)


def fuzzel_teardown(_):
    subprocess.run(["pkill", "-x", "-TERM", "fuzzel"], check=False)
    subprocess.run(["pkill", "-x", "-TERM", ".fuzzel-wrapped"], check=False)


def wait_absent(present, timeout=8.0):
    t0 = time.perf_counter()
    while time.perf_counter() - t0 < timeout:
        if not present():
            return True
        time.sleep(0.02)
    return False


def bench(app, cmd, present, teardown, n):
    times = []
    for i in range(n):
        if present():
            sys.exit(f"{app}: already present before run {i} — dirty state, aborting")
        t0 = time.perf_counter()
        req({"Action": {"Spawn": {"command": cmd}}})
        hit = None
        while time.perf_counter() - t0 < 10.0:
            hit = present()
            if hit:
                break
        t1 = time.perf_counter()
        if not hit:
            sys.exit(f"{app}: run {i} never appeared within 10 s — failing loudly")
        ms = (t1 - t0) * 1000.0
        times.append(ms)
        print(json.dumps({"app": app, "run": i, "ms": round(ms, 1),
                          "load1": round(os.getloadavg()[0], 2),
                          "cold": i == 0}), flush=True)
        teardown(hit)
        if not wait_absent(present):
            sys.exit(f"{app}: run {i} teardown failed — dirty state, aborting")
        time.sleep(0.5)
    warm = sorted(times[1:])
    print(json.dumps({"app": app, "summary": True, "n": n,
                      "cold_ms": round(times[0], 1),
                      "warm_min": round(warm[0], 1),
                      "warm_median": round(warm[len(warm) // 2], 1),
                      "warm_max": round(warm[-1], 1)}), flush=True)


# app table: name -> (spawn argv, window app_id or None for layer-shell, proc name)
APPS = {
    "kitty":     (["kitty"], "kitty", "kitty"),
    # glvnd pinned to the mesa EGL ICD only — isolates the nvidia-ICD
    # enumeration cost (4.8). env(1) adds exec cost to THIS arm only,
    # biasing the measured nvidia tax low, never high.
    "kitty-mesa": (["env",
                    "__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json",
                    "kitty"], "kitty", "kitty"),
    # same pin, NixOS ICD path (4.9)
    "kitty-mesa-nixos": (["env",
                    "__EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json",
                    "kitty"], "kitty", "kitty"),
    "kitty-noconf": (["kitty", "--config", "NONE"], "kitty", "kitty"),
    "foot":      (["foot"], "foot", "foot"),
    "alacritty": (["alacritty"], "Alacritty", "alacritty"),
    "ghostty":   (["ghostty"], "com.mitchellh.ghostty", "ghostty"),
    "fuzzel":    (["fuzzel"], None, "fuzzel"),
}

n = int(sys.argv[1]) if len(sys.argv) > 1 else 10
apps = (sys.argv[2] if len(sys.argv) > 2 else "kitty,fuzzel").split(",")
print(json.dumps({"meta": True, "socket": sock_path, "n": n, "apps": apps,
                  "os": open("/etc/os-release").readline().strip(),
                  "load1_start": round(os.getloadavg()[0], 2)}), flush=True)
for name in apps:
    argv, app_id, proc = APPS[name]
    if app_id is None:
        bench(name, argv, fuzzel_present, fuzzel_teardown, n)
    else:
        bench(name, argv,
              (lambda a: lambda: win_present(a))(app_id),
              (lambda p_: lambda _hit: win_teardown(p_))(proc), n)
