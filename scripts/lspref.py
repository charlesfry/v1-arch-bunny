"""Time textDocument/references against a real project, no editor in the way.

nvim was tried first and could not be used: pyright answers a raw stdio client
in 0.69 s but went silent against nvim's LSP client, so every nvim number was a
harness artifact. This talks to the server directly.

Usage: scripts/lspref.py <root> <file> <line0> <char0> [repeats]
See benchmarks/3.12.gr-after-the-exclude.md for what it was built to answer.
"""
import json, os, subprocess, sys, threading, time

root, path = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
line, char = int(sys.argv[3]), int(sys.argv[4])
repeats = int(sys.argv[5]) if len(sys.argv) > 5 else 3
CMD = [os.path.expanduser("~/.local/share/nvim/mason/bin/pyright-langserver"), "--stdio"]

p = subprocess.Popen(CMD, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                     stderr=subprocess.DEVNULL, bufsize=0)
seen, lock = {}, threading.Lock()

def send(msg):
    b = json.dumps(msg).encode()
    p.stdin.write(b"Content-Length: %d\r\n\r\n" % len(b) + b)
    p.stdin.flush()

def reader():
    buf = b""
    while True:
        c = p.stdout.read(1)
        if not c:
            return
        buf += c
        if buf.endswith(b"\r\n\r\n"):
            n = int([l for l in buf.split(b"\r\n")
                     if l.lower().startswith(b"content-length")][0].split(b":")[1])
            body = b""
            while len(body) < n:
                body += p.stdout.read(n - len(body))
            m = json.loads(body)
            with lock:
                if "id" in m and ("result" in m or "error" in m):
                    seen[m["id"]] = m
                elif "id" in m:                 # server->client request: must reply
                    send({"jsonrpc": "2.0", "id": m["id"], "result": None})
            buf = b""

def wait(i, limit):
    t = time.time()
    while time.time() - t < limit:
        with lock:
            if i in seen:
                return time.time() - t
        time.sleep(0.005)
    return None

threading.Thread(target=reader, daemon=True).start()
uri = "file://" + path
send({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {
    "processId": os.getpid(), "rootUri": "file://" + root, "capabilities": {},
    "workspaceFolders": [{"uri": "file://" + root, "name": "probe"}]}})
el = wait(1, 60)
print(f"initialize_ms={el*1000:.1f}" if el else "initialize=TIMEOUT")
send({"jsonrpc": "2.0", "method": "initialized", "params": {}})
send({"jsonrpc": "2.0", "method": "textDocument/didOpen", "params": {"textDocument": {
    "uri": uri, "languageId": "python", "version": 1, "text": open(path).read()}}})

# Report every call: 3.10 showed a server can answer fast and wrong before
# indexing settles, so a single number would hide a partial result.
nid = 10
for k in range(repeats):
    nid += 1
    t = time.time()
    send({"jsonrpc": "2.0", "id": nid, "method": "textDocument/references", "params": {
        "textDocument": {"uri": uri}, "position": {"line": line, "character": char},
        "context": {"includeDeclaration": True}}})
    el = wait(nid, 300)
    label = "cold" if k == 0 else f"warm{k}"
    if el is None:
        print(f"{label}\tTIMEOUT(300s)")
    else:
        r = seen[nid].get("result") or []
        files = len({x["uri"] for x in r})
        print(f"{label}\telapsed_ms={el*1000:.1f}\trefs={len(r)}\tfiles={files}")
p.kill()
