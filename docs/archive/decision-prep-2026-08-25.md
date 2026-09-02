# Decision-prep — 2026-08-25 (autonomous, non-GUI)

Drives the morning-report question queue toward one-word answers, with data or
draft text. **Nothing here is decided or applied** — CHOICES.md (the ledger) is
untouched; these are proposals for the author to accept, edit, or reject. GUI-
dependent items are marked BLOCKED (box is idle-locked, see `benchmarks/4.22`).

Already closed elsewhere this session: **#7** nvidia-open switch (priced,
recommend switch — `benchmarks/4.21`); **#10** editor draft (+14.8 ms, re-affirm
— `benchmarks/4.23`); **#13** playerctl/orca (nothing to decide).

---

## #1 Font delivery — recommend: vendor the OFL TTFs

Data (on box): `~/.local/share/fonts/` holds `FragmentMono-Regular.ttf` (125 KB)
and `FragmentMono-Italic.ttf` (128 KB), **owned by no package** (`pacman -Qo` →
"No package owns") — confirming `ttf-fragment-mono` is dead. Fragment Mono is a
Google Fonts family, **almost certainly SIL OFL 1.1** (Google Fonts default; I
could not read the license string from the TTF name table on the box — verify the
exact license when vendoring, but the recommendation holds under OFL *or* Apache,
both of which permit bundling with the license file). The family is only Regular +
Italic
(two styles), so those two files are the complete family (kitty bold falls back /
synthesizes — unchanged from today).

**Recommendation: vendor the two TTFs in the repo** (e.g. `assets/fonts/` with
`OFL.txt` alongside), installer symlinks them into `~/.local/share/fonts/` and
runs `fc-cache`. This matches the repo's symlink-deployment pattern and is the
"it just works" option: no network at install, no megapackage.
- *google-fonts megapackage*: hundreds of families' worth of audit surface to get
  one font — rejected on the complexity (not disk) test.
- *curl-at-install*: adds a network dependency to a step that otherwise needs
  none; fragile per priority 1. Rejected.
OFL redistribution is explicitly permitted (bundle the license, don't sell the
font alone) — vendoring is compliant.

## #3 Status-cell bold / awk bug — recommend: normalize the cells

Confirmed real and consequential. **11 rows wrap the status cell in `**…**`**, and
the documented `awk '$5=="picked"'` matches only unbolded ` picked `, so it
**silently drops the two headline packages**:

- L35 `compositor` **picked** → **niri dropped**
- L55 `terminal` **picked** → **kitty dropped**
- (plus 9 bold rejected/deferred: L34 compositor, L56/57/58 terminal, L72
  shell-startup, L73 prompt, L74 node-runtime, L79 xwayland, L82 prompt-hooks)

Two fixes; **recommend normalize** (strip the `**` from all 11 status cells),
matching the precedent the author already set for the Packages-column format debt
("the column's whole justification is that it is data"). Emphasis, if wanted,
belongs in the Note, not the data column. The alternative — widening the awk to
`$5 ~ /picked/` or stripping `*` — leaves the data column inconsistent and every
future consumer re-implementing the tolerance. One-time normalize is cleaner.
(I can apply this mechanically on your go-ahead — it's a formatting fix, not a
decision, but it touches 11 ledger rows so I'm holding.)

## #2 Vendor-conditional Packages convention — recommend: Packages = unconditional only

The four cells that carry prose (`gpu-driver` Intel-mesa, `firmware-set`
brace-list + `-amd`, `microcode` `amd-ucode **or** intel-ucode`, `jupyter`
venv-split) all encode *hardware/vendor conditionals* inside a column whose job is
to be a flat package list. **Recommendation: keep the Packages column to packages
that install unconditionally on every BunnE machine; move every conditional to
installer logic keyed on detected hardware, documented in Note.** So `microcode`'s
cell becomes `—` (Note: "installer picks amd-ucode|intel-ucode from
`/proc/cpuinfo` vendor"), `gpu-driver` lists the always-installed set and Note
carries the Intel-iGPU addition, etc. This keeps the awk trivially correct
(Packages = the guaranteed set) and puts conditionality where it must live anyway
(install-time detection), rather than inventing a column-per-vendor the awk would
then have to understand. venv packages (`jupyter`) aren't pacman packages at all —
they belong in a "venv:" Note, never the pacman Packages column.

## #5 Docker base row — draft below

No row picks `docker` itself; only `docker-storage-quota` (L29) governs its
storage. Docker is installed, `docker.socket` enabled (socket-activated, so no
idle daemon until first use). Draft row:

> `| docker | docker (+ compose plugin if wanted) | docker | picked | 2026-08-25 | socket-activated (`docker.socket`), 0 idle daemon until first `docker` call; storage governed by `docker-storage-quota` | Data-science workload staple. Installed but rowless until now (4.21 audit). Ships the daemon **socket-activated, not enabled** — the dockerd cost is paid only on first use, consistent with priority 2b. User must be in the `docker` group (installer step). Storage caps live in `docker-storage-quota`; this row is just the component pick. |`

Open sub-question for you: ship `docker-compose`/`docker-buildx` plugins, or bare
`docker`? (Bare keeps it minimal; compose is commonly assumed for DS.)

## #9 oom / load-protection — mechanisms proven (4.18), drafts below

**oom-protection** (L32, deferred→picked). 4.18: swap-kill canary PASSED (killed
exactly the hog cgroup at >90% swap, kernel OOM never fired, instant recovery).
Resident cost now measured: **1.4 MB (cgroup MemoryCurrent) / 5.7 MB VmRSS** — the
"~1-2 MB class" estimate holds. Draft:

> `| oom-protection | systemd-oomd | — | picked | 2026-08-25 | swap-kill canary PASS (4.18): killed the hog cgroup at >90% swap, kernel OOM never fired, recovery <5 s; resident ~1.4 MB | Config: enable `systemd-oomd`; drop-ins `ManagedOOMSwap=kill` on `-.slice`, `ManagedOOMSwap=kill`+`ManagedOOMMemoryPressure=kill` on `user@.service`. Ships with systemd (no new package). Pressure-kill path configured but unexercised (ramp too fast for sustained PSI) — a slow-leak canary would test it. |`

**load-protection** (L49, deferred→picked). 4.18: `CPUWeight=1` halves a hog's
damage to kitty spawn (504→330 ms); `CPUWeight=1 + AllowedCPUs` (reserve 2 cores)
returns to baseline (149 ms vs 141.6). Zero packages. Draft:

> `| load-protection | systemd slice weighting + core reservation | — | picked | 2026-08-25 | 4.18: hog inflates kitty spawn 141.6→504 ms; CPUWeight=1 →330; +AllowedCPUs (reserve 2 cores) →149 ms ≈ baseline | Launch heavy jobs into a deprioritized slice: `systemd-run --user -p CPUWeight=<low> -p AllowedCPUs=<all-but-N>`. Pure systemd, 0 packages, 0 resident. Serves priority 2a against the user's stated top pain (resource exhaustion). Caveats: n=5, one CPU-spin hog shape, IO load untested. |`

## #8 fzf + lazygit — recommend: `lazygit` yes; `fzf` only if the picker is fzf-lua

**`lazygit` — add it.** It backs `<leader>gg`, a LazyVim default; omitting it ships
a broken keybind (same class as Finding 2 in 4.21). Unambiguous.

**`fzf`-the-binary — NOT needed by the editor.** Verified headless: **snacks.nvim
is the only picker installed** in both the draft and the baseline; `fzf-lua` is an
*unenabled* LazyVim extra (lazyvim.json has zero extras) and LazyVim's
`picker = "auto"` selects snacks. snacks.picker is pure-Lua and never spawns the
`fzf` binary — this also matches 3.13's "keep snacks.picker" recommendation. So
**drop `fzf` from the editor dep set.** Its only remaining justification is
**bash shell integration** (Ctrl-R fuzzy history / Ctrl-T) — a *separate* decision
about the shell, not the editor; decide that on its own merits. `lazygit`,
`ripgrep`, `fd` are the real editor system-deps; `fzf` is not one of them.

## #12 greetd — the trade, your pick (measured, 4.19)

Not mine to decide (it's a 6.8 MB-forever vs 0 MB taste call), but stated plainly:
greetd buys a **supervised session + a real greeter on logout** for **~6.8 MB PSS
resident forever**; getty-autologin is **0 MB** with an instant re-login loop and
no greeter. No boot-time difference (within noise). Given priority 2b and that the
box is single-user autologin, **getty-autologin is the lighter default**; greetd
earns its 6.8 MB only if you want the supervised-session / logout-greeter
behavior. Recommend getty-autologin unless that behavior is wanted.

---

## Resolved live this session
- **#6 LICENSE** — DONE: `LICENSE` (MIT, Copyright 2026 Charles Fry) written to the tree (uncommitted, like the rest) per your "it's open source, idgaf."
- **#3 status normalization** — DONE: 11 status cells de-bolded (verified: only col 5 changed, `**` count −22); the generator awk now emits niri + kitty.
- **#4 satty keybind** — pipeline **VERIFIED** (box unlocked): `grim -g … - | satty -f -` launches satty from the piped grab; grim writes a valid PNG to stdout, satty reads `-f -`. Proposed bind `Mod+Print { spawn-sh "grim -g \"$(slurp)\" - | satty -f -"; }` — only the slurp region-drag is inherently interactive (proven tool). Ready for the Phase-4 keybind block; your chord to confirm.

## Still yours alone (no prep possible)
- **#11 upstream reports** (niri `Handled`-while-locked; molten `:e`-reload) — file or not, your call.
- **#14 palette** — envsubst verdict confirmed by measurement; needs your one-word ratify.
