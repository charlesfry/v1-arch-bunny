"""Time picker open -> screen settled, for the same list of LSP-reference rows.

Two msgpack-RPC connections to one nvim: one attaches as a real UI and
timestamps every redraw batch, the other issues the trigger. "Settled" = no
redraw for QUIET ms; the reported time runs from the trigger to the last redraw
before that silence. A screen-level number, not a Lua-return number.

pynvim was tried and abandoned -- its greenlet loop deadlocks when a second
thread issues requests. This speaks the protocol directly.

Usage: scripts/pickerbench.py <picker> <n> [repeats]   (needs msgpack)
See benchmarks/3.13.picker-bakeoff.md.
"""
import os, socket, subprocess, sys, tempfile, threading, time
import msgpack

picker, N = sys.argv[1], int(sys.argv[2])
repeats = int(sys.argv[3]) if len(sys.argv) > 3 else 5
QUIET = 0.20

class Conn:
    def __init__(self, path):
        self.s = socket.socket(socket.AF_UNIX); self.s.connect(path)
        self.up = msgpack.Unpacker(raw=False); self.mid = 0
        self.resp = {}; self.lock = threading.Lock()
        self.on_notify = None
        threading.Thread(target=self._read, daemon=True).start()
    def _read(self):
        while True:
            d = self.s.recv(65536)
            if not d: return
            self.up.feed(d)
            for m in self.up:
                if m[0] == 1:
                    with self.lock: self.resp[m[1]] = m
                elif m[0] == 2 and self.on_notify:
                    self.on_notify(m[1], m[2])
    def call(self, method, *args, timeout=25):
        self.mid += 1; mid = self.mid
        self.s.sendall(msgpack.packb([0, mid, method, list(args)], use_bin_type=True))
        t = time.time()
        while time.time() - t < timeout:
            with self.lock:
                if mid in self.resp:
                    m = self.resp.pop(mid)
                    if m[2] is not None: raise RuntimeError(f"{method}: {m[2]}")
                    return m[3]
            time.sleep(0.002)
        raise TimeoutError(method)

SETUP = f"""
local rows = {{}}
for i = 1, {N} do
  rows[i] = string.format('tasks/fm_np/code/core/transform.py:%d:%d: adstocked = get_adstock_saturated_media_jax(', i, (i % 40) + 1)
end
_G.BENCH_ROWS = rows
_G.BENCH_ITEMS = vim.tbl_map(function(s)
  local f, l, c = s:match('^([^:]+):(%d+):(%d+)')
  return {{ text = s, file = f, pos = {{ tonumber(l), tonumber(c) }} }}
end, rows)
_G.BENCH_QF = vim.tbl_map(function(s)
  local f, l, c, t = s:match('^([^:]+):(%d+):(%d+): (.*)$')
  return {{ filename = f, lnum = tonumber(l), col = tonumber(c), text = t }}
end, rows)
"""

OPEN = {
  'snacks':    "require('snacks').picker.pick({ items = _G.BENCH_ITEMS, format = 'text' })",
  'fzf':       "require('fzf-lua').fzf_exec(_G.BENCH_ROWS, {})",
  'telescope': ("local p=require('telescope.pickers') local f=require('telescope.finders') "
                "local c=require('telescope.config').values "
                "p.new({}, { prompt_title='refs', finder=f.new_table({results=_G.BENCH_ROWS}), "
                "sorter=c.generic_sorter({}) }):find()"),
  'quickfix':  "vim.fn.setqflist(_G.BENCH_QF) vim.cmd('copen')",
}
CLOSE = {
  'snacks':    "pcall(function() for _,p in ipairs(require('snacks').picker.get()) do p:close() end end)",
  'fzf':       "vim.api.nvim_input('<Esc>')",
  'telescope': "vim.api.nvim_input('<Esc>')",
  'quickfix':  "vim.cmd('cclose')",
}

sock = os.path.join(tempfile.mkdtemp(), 'nvim.sock')
env = dict(os.environ); base = os.environ['CLAUDE_JOB_DIR'] + '/tmp'
env.update(XDG_CONFIG_HOME=base + '/pickcfg', XDG_DATA_HOME=base + '/pickdata',
           XDG_STATE_HOME=base + '/pickstate', XDG_CACHE_HOME=base + '/pickcache')
proc = subprocess.Popen(['nvim', '--headless', '--listen', sock], env=env,
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
for _ in range(200):
    if os.path.exists(sock): break
    time.sleep(0.05)
time.sleep(0.4)

ui, ctl = Conn(sock), Conn(sock)
last = [0.0]
ui.on_notify = lambda name, args: last.__setitem__(0, time.time()) if name == 'redraw' else None
ui.call('nvim_ui_attach', 160, 48, {'rgb': True, 'ext_linegrid': True})
time.sleep(0.6)

ctl.call('nvim_exec_lua', SETUP, [])
t = time.time()
if picker != 'quickfix':
    mod = {'snacks': 'snacks', 'fzf': 'fzf-lua', 'telescope': 'telescope'}[picker]
    ctl.call('nvim_exec_lua', f"require('{mod}')", [])
load_ms = (time.time() - t) * 1000

def settle(trigger):
    last[0] = 0.0
    t0 = time.time()
    try: ctl.call('nvim_exec_lua', trigger, [])
    except Exception as e: return None
    deadline = t0 + 20
    while time.time() < deadline:
        if last[0] and (time.time() - last[0]) > QUIET:
            return (last[0] - t0) * 1000
        time.sleep(0.004)
    return None

times = []
for _ in range(repeats):
    el = settle(OPEN[picker])
    try: ctl.call('nvim_exec_lua', CLOSE[picker], [])
    except Exception: pass
    time.sleep(0.5)
    if el is not None: times.append(el)

times.sort()
if times:
    med = times[len(times) // 2]
    print(f"{picker:10s} n={N:<5d} load_ms={load_ms:7.1f}  open_med={med:7.1f}  "
          f"min={times[0]:7.1f}  max={times[-1]:7.1f}  runs={len(times)}/{repeats}")
else:
    print(f"{picker:10s} n={N:<5d} load_ms={load_ms:7.1f}  NO RENDER DETECTED")
proc.kill()
