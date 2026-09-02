"""The first find-references is wrong in every arm. Can waiting fix it?

Three strategies, same server, same symbol, each in a fresh process:
  naive  - ask immediately after didOpen (what an editor does today)
  diag   - wait for publishDiagnostics on the file, then ask
  settle - wait for diagnostics, then poll until two calls agree
Prints what the FIRST answer the user would see is, and what it cost.
See benchmarks/3.13.picker-bakeoff.md.
"""
import json, os, subprocess, sys, threading, time

mode, D, F = sys.argv[1], sys.argv[2], sys.argv[3]
CMD = [os.path.expanduser("~/.local/share/nvim/mason/bin/pyright-langserver"), "--stdio"]
p = subprocess.Popen(CMD, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                     stderr=subprocess.DEVNULL, bufsize=0)
seen, lock, diag = {}, threading.Lock(), []

def send(m):
    b = json.dumps(m).encode()
    p.stdin.write(b"Content-Length: %d\r\n\r\n" % len(b) + b); p.stdin.flush()

def reader():
    buf = b""
    while True:
        c = p.stdout.read(1)
        if not c: return
        buf += c
        if buf.endswith(b"\r\n\r\n"):
            n = int([l for l in buf.split(b"\r\n") if l.lower().startswith(b"content-length")][0].split(b":")[1])
            body = b""
            while len(body) < n: body += p.stdout.read(n - len(body))
            m = json.loads(body)
            with lock:
                if "id" in m and ("result" in m or "error" in m): seen[m["id"]] = m
                elif m.get("method") == "textDocument/publishDiagnostics": diag.append(time.time())
                elif "id" in m: send({"jsonrpc":"2.0","id":m["id"],"result":None})
            buf = b""

def wait(i, limit=120):
    t = time.time()
    while time.time() - t < limit:
        with lock:
            if i in seen: return time.time() - t
        time.sleep(0.004)
    return None

t0 = time.time()
threading.Thread(target=reader, daemon=True).start()
uri = "file://" + F
send({"jsonrpc":"2.0","id":1,"method":"initialize","params":{
    "processId": os.getpid(), "rootUri":"file://"+D, "capabilities":{},
    "workspaceFolders":[{"uri":"file://"+D,"name":"probe"}]}})
wait(1)
send({"jsonrpc":"2.0","method":"initialized","params":{}})
send({"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"textDocument":{
    "uri":uri,"languageId":"python","version":1,"text":open(F).read()}}})

def refs(i):
    send({"jsonrpc":"2.0","id":i,"method":"textDocument/references","params":{
        "textDocument":{"uri":uri},"position":{"line":131,"character":10},
        "context":{"includeDeclaration":True}}})
    el = wait(i)
    return (len(seen[i].get("result") or []) if el is not None else None), el

wait_ms = 0.0
if mode in ("diag", "settle"):
    w = time.time()
    while not diag and time.time() - w < 120: time.sleep(0.005)
    wait_ms = (time.time() - w) * 1000

t = time.time()
if mode == "settle":
    prev, n, i = None, None, 30
    while time.time() - t < 120:
        n, _ = refs(i); i += 1
        if prev is not None and n == prev: break
        prev = n
        time.sleep(0.05)
    call_ms = (time.time() - t) * 1000
    calls = i - 30
else:
    n, el = refs(30)
    call_ms = (el or 0) * 1000
    calls = 1

print(f"{mode:7s} first_answer_refs={n}  wait_for_diagnostics_ms={wait_ms:8.1f}  "
      f"call_ms={call_ms:8.1f}  calls={calls}  total_ms={(time.time()-t0)*1000:8.1f}")
p.kill()
