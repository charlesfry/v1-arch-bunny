# The cost budget

A running tally of what BunnE spends on features, so that "imperceptibly slow"
cannot quietly aggregate into "noticeably slow". Requested by the author
2026-08-21.

Decisions live in [`CHOICES.md`](CHOICES.md); the numbers behind them live in
[`benchmarks/`](benchmarks/). **This file is neither — it is the sum.** A row
here is a concession against `CLAUDE.md` priority 2, recorded so it can be
reviewed as a group rather than defended one at a time.

## How to read it, and the mistake it exists to prevent

**Costs are bucketed by how often they are paid, and buckets are never added
together.** This is the whole point. On 2026-08-21 a 460 ms cost was chased hard
on the belief it was paid per terminal; it turned out to be paid once per login,
and the genuinely expensive thing — 15 ms of direnv on *every prompt* — had been
sitting unmeasured next to it. A millisecond in the prompt bucket is worth
roughly 200 milliseconds in the login bucket on a normal day.

Rough daily frequencies used to convert between buckets:

| Bucket | Times per day | 1 ms here is worth |
|---|---|---|
| per prompt | ~200 | 200 ms/day |
| per new terminal | ~20 | 20 ms/day |
| per session login | ~1 | 1 ms/day |
| per boot | ~1 | 1 ms/day |
| resident RAM | always | — |

## Rules

1. **Every `picked` row in `CHOICES.md` that costs runtime gets a row here.**
   If it costs nothing measurable, say so with a zero — an absent row is
   indistinguishable from an unmeasured one.
2. **State the bucket.** A cost with no bucket is not usable.
3. **State what it buys.** A budget of costs with no benefits argues for an
   empty machine.
4. **When a bucket exceeds its budget, review the whole bucket** — not just the
   row that crossed the line. The last feature added is not automatically the
   one least worth keeping.
5. Numbers taken on the Omarchy desktop are inflated at a variable rate by its ML workload
   (`benchmarks/3.4`); prefer `bunne-test` figures and mark which is which. If you do not have ssh
   access to bunne-test, flag it to the author and he will almost certainly
   give you access in order to improve test quality.
6. Just because this is a budget does not give you license to fill up the budget without justification.
   Every shaved ms is a win regardless of whether it violates the budget constraint.
   Even if adding a new item will keep us under budget it still has to
   earn its keep.

---

## Bucket: per prompt — after every command

**Budget: 20 ms. Currently 8.4 ms (42%).**

Rationale for 20 ms: a response under ~50 ms reads as instantaneous, and the
prompt is the single most repeated interaction on the machine. 20 ms leaves
headroom while staying well inside perception.

| What we added | Where it lives | Why we added it | What it costs | Ledger |
|---|---|---|---|---|
| `_bunne_prompt` — dir + branch | `bash/rc` → `PROMPT_COMMAND` | Know which repo and branch you are on without running a command. Reads `.git/HEAD` directly, so it never forks. | **0.10 ms** | `prompt` |
| `_bunne_prompt` — dirty marker `●` | same function, `git status --porcelain` | See uncommitted work at a glance. **Author's explicit call, 2026-08-21: "8ms is worth it."** Prevents the classic loss — finishing a task and leaving it uncommitted. | **8.2 ms** | `prompt` |
| `_bunne_direnv` | `bash/rc` → `PROMPT_COMMAND` | Per-project env vars (`.envrc`). Gated on a `$PWD` change so it forks on `cd`, not on every command. | **0.23 ms** | `prompt-hooks` |
| **Total** | | | **~8.4 ms** | |

*Replaced: starship 35–43 ms + ungated direnv 15.0 ms = 65.7 ms (desktop, loaded).*
**The dirty marker is 98% of this bucket** and was kept deliberately by the
author — it is the first thing to re-examine if the budget is ever breached.

## Bucket: per new terminal

**Budget: 100 ms. Currently ~9 ms (9%).**

Rationale: 100 ms is the long-standing threshold for an action feeling
instantaneous. The author names the terminal his most-used application.

| What we added | Where it lives | Why we added it | What it costs | Ledger |
|---|---|---|---|---|
| Arch `nodejs` (no `mise`) | `/usr/bin/node` — nothing in the shell config | **Not for the author's use — he never runs node.** After `agent-clis` dropped the four npm CLIs, its only consumers are three Neovim tools: `pyright-langserver`, `sql-formatter`, `vscode-json-language-server`. `mise` was dropped entirely — it pinned a version nobody needed, and a plain package needs no shell integration. **Whether node survives at all is now an editor-slot question.** | **0 ms** | `node-runtime` |
| `conda.sh` sourced | `bash/rc`, guarded `source` | Conda envs for data science. Costs almost nothing because it only *defines a function*; the 2341 ms hook is deferred to `conda activate`. **This is the pattern the others were made to copy.** | **0.3 ms** | — |
| aliases, helpers, prompt setup | `bash/rc` | `vi`→`nvim`, git helpers, VPN aliases, the prompt functions above. | ~9 ms | — |
| **Total over bare bash** | | | **~9 ms** | |

*Replaced: Omarchy's `.bashrc` at 272–317 ms, of which `mise activate` alone was
143 ms.*

## Bucket note: per editor launch (added 2026-08-24)

LazyVim picked (`editor` row) at a measured **~127 ms to a 1500-line .py**
vs 16-24 ms alternatives — the author's explicit trade, stated in the row:
molten-without-brittleness + muscle memory bought with ~110 ms per nvim
launch. Frequency sits between the terminal and login buckets (editor
launches/day are workload-dependent); revisit only if LazyVim's own
plugin growth pushes it past ~150 ms, the 4.15 flag line.

## Bucket note: per snapshot deletion (added 2026-08-26)

**A bucket nobody had been counting, found by measuring a cost we had just decided to keep.**
`btrfs quota` stays enabled on `cryptroot` after open question 26 dropped the Docker qgroup
*limits*. `benchmarks/4.29` measured what the accounting costs, n=9 per arm on a loopback
with `bunne-test`'s real 24-snapshot shape:

| operation | quota off | quota on | Δ |
|---|---|---|---|
| extract 6457 files | 0.591 s | 0.600 s | **no effect established** (ranges overlap) |
| `rm -rf` 6457 files | 0.236 s | 0.271 s | +0.035 s |
| `subvolume snapshot` | 0.031 s | 0.053 s | +0.022 s |
| **`subvolume delete`** | **0.008 s** | **0.355 s** | **+0.347 s each, 46×** |

**Frequency is snapper's cleanup timer, not a keystroke** — `NUMBER_LIMIT=2-15` means
snapper retires snapshots on its own schedule, so nothing waits on this at the keyboard.
**But btrfs transaction commits are filesystem-wide**, the same scoping fact that made
`4.27` dangerous: 1.8 s of commit spent on qgroup accounting is 1.8 s in which every other
writer to `/` waits. A cleanup retiring several snapshots while the author saves a file is a
stall he can feel, and the 0.355 s figure comes from a **200 MB** subvolume — the real root
is ~4 GB, so treat it as a floor.

**What it buys, and why it is not up for trimming:** not the notification. `man 5
snapper-configs` on the machine — `QGROUP` is *"the btrfs quota group used for space aware
cleanup algorithms"*, and `/etc/snapper/configs/root` carries `SPACE_LIMIT="0.08"` and
`FREE_LIMIT="0.2"`. Both run on that qgroup. Disabling quotas would silently switch off
snapper's space-based retention — part of gripe #2's fix — as well as two of the alert's
three meters. Rows: `docker-storage-quota`, `snapshot-system`, `disk-alert`.

**Not measured:** whether the stall is observable end-to-end from a writer's point of view,
and how 0.355 s scales from a 200 MB subvolume to a 4 GB one.

## Bucket: per session login

**Budget: 500 ms. Currently ~76 ms (15%) on a fresh install.**

| What we added | Where it lives | Why we added it | What it costs | Ledger |
|---|---|---|---|---|
| `vapoursynth.sh` | `/etc/profile.d/` — **Arch's file, not ours** | **We did not add it and it buys us nothing.** It arrives three levels down: `mpv` → `ffmpeg` → `vapoursynth`. It forks a Python binary to print a constant path. Kept only because every removal is worse than the disease. | **64 ms** fresh, 460 ms mature; re-measured 66-83 ms on the 2026-08-23 install (idle, n=5) | `shell-startup` |
| `debuginfod.sh` | `/etc/profile.d/` — Arch's file | Lets `gdb` auto-fetch debug symbols. Marginal on a data-science box; two `find` pipelines (four processes) to read one 33-byte file. | 12.4 ms | `shell-startup` |
| `locale.sh`, `perlbin.sh`, `gawk.sh`, … | `/etc/profile.d/` — Arch's files | Locale and tool paths. Genuinely needed, genuinely cheap. | ~5 ms | `shell-startup` |
| `waybar` | `spawn-at-startup` (niri) | **Costs this bucket nothing, and the zero is the point** — see the correction below. niri forks it and carries on; the bar finishes drawing 86 ms later (n=3, no spread) in its own process, after the compositor is already up and taking input. Nothing waits on it. | **0 ms** (86 ms to draw, concurrent) | `status-bar` |
| **Total** | | | **~76 ms** | |

**CORRECTION, 2026-08-26 — waybar was added to this table at 86 ms and the total was
reported as 167 ms. That was wrong, and the author caught it** (*"doubling the per-login
wait time is rough"*). It is the exact failure this file's own header warns about: **this
bucket sums things that happen one after another in the login shell, and waybar is not one
of them.** `/etc/profile.d` scripts run serially inside bash before `exec niri-session`; niri
then *forks* waybar and keeps going, so its 86 ms of GTK startup runs in another process on
another core while the compositor is already rendering. Adding a concurrent cost to a serial
total is the same error as summing two different buckets.

**Re-measured directly rather than argued**: `hyperfine -N "bash -lc true"` on `bunne-test`
gives **75.7 ms ± 0.6 (n=39)**, and `waybar` appears nowhere in `~/.bash_profile`,
`~/.bashrc`, `/etc/profile` or `/etc/profile.d`. **The per-login wait did not change when the
bar was added.** The 81 ms above was itself an older estimate; 75.7 ms is the current figure
and the table now reads ~76 ms.

**Accepted, not fixed.** The vapoursynth line buys nothing and is the largest
single item, but the only fixes are a `NoExtract` hack or a forced dependency
removal — both rejected as worse than the disease. It grows with `site-packages`
(460 ms on the 4-year-old desktop), so **re-measure on a mature machine before
concluding it is still fine.**

## Bucket: per boot — to `graphical.target`

**Budget: 3 s. Currently ~2.3 s (77%).**

| What we added | Where it lives | Why we added it | What it costs | Ledger |
|---|---|---|---|---|
| base system | `archinstall` JSON: LUKS2, btrfs, limine | The floor. Nothing to trim without losing encryption or snapshots. | 2.095 s | `benchmarks/2.1` |
| limine menu `timeout: 3` | `/boot/limine.conf` | The recovery window. Author chose 3 s over 1 s so the snapshot menu is reachable on a misbehaving machine — priority 1 over 2a, accepted knowingly. | **+2 s** every boot (16 s → 18 s median shutdown-to-kernel, n=3/arm) | `snapshot-boot-entries` |
| `pipewire-audio` + `wireplumber` | packages; socket-activated units | Audio must work out of the box, Bluetooth included (`02-functionality.md` C4). Socket activation means 0 MB until a client connects. | +0.21 s | `audio` |
| **Total** | | | **~2.3 s** | |

Note `sshd` sits on this critical chain on `bunne-test` only — a test-rig
deviation, not shipped (`ssh`).

## 2026-08-24 additions (zero-rows and driver impact)

- **keybind apps** (`keybind-apps` row: spotify-launcher, btop, lazydocker,
  signal-desktop, bitwarden, playerctl, nautilus): **0 resident, 0 boot,
  0 login** — every one launches on keypress and dies with its window.
  Bitwarden's autostart temptation is the known trap (455 MB resident when
  it autostarts — observed on the NixOS box, author disabled it); BunnE
  ships no autostart for any of these.
- **nvidia-open (gpu-driver)**: no new resident *process*, but the driver
  stack is mapped by the compositor — niri settles ~90 MB PSS vs 82.7
  pre-driver (`4.12`, ~+8 MB), and kitty pays ~7-10 ms per warm launch via
  glvnd ICD enumeration (`4.8b`; per-terminal bucket: at ~20 terminals/day,
  ~0.2 s/day — accepted with the driver decision, pin declined). kitty's
  own RAM, per 4.14/b/c (three DA rounds), **censoring closed by `4.16`
  (3 h idle run, 40 samples): steady-state anon is 54.33 MB per idle
  window** — bit-identical across every sample from age 600 s to 10,800 s,
  so the 4.14 "drift" is a one-time +3.5 MB settling step complete by age
  600 s, not ongoing growth; 50.74-50.79 MB stays the *transient spawn
  value* (n=7 now, 4.16 replicated it at 50.788). **No total PSS is quotable, ever, without its full recipe**
  — the 102-106 MB convention FAILED replication (4.14c read 86-90 under
  the nominal pin); totals are page-cache-warmth accounting, causally
  demonstrated (n=1, pre-registered, 3.4×) by the drop_caches boot. File
  pages are still RAM in use (2b) and refault on the 2a path under
  pressure. Untested: anon past 300 s, additivity across windows, growth
  under real work.

## 2026-08-25 additions

- **snapshot boot entries** (`snapshot-boot-entries` row: `limine-snapper-sync`,
  picked today): **0 resident as shipped.** The package's
  `limine-snapper-sync.service` runs a bash watcher that clears a stale pacman
  `db.lck` and then exits when `inotifywait` is not on `PATH`, handing entry sync
  to snapper's own plugin hook — so BunnE deliberately does not install the
  `inotify-tools` optdep. Installing it would turn the unit into a resident
  process at **456 kB PSS / 4 MiB cgroup** (measured on the author's Omarchy
  desktop, which runs it that way). Per-boot cost is that one short script on
  `multi-user.target`; **not yet measured on `bunne-test`** — time it during the
  acceptance run. Per pacman transaction the sync copies a kernel+initramfs pair
  to the ESP only when that build is new (content-hash dedup), so the usual
  transaction pays a hash check. ESP bytes are not a budget metric — disk is not a
  criterion — but the FAT partition is finite, and the row carries the guardrails.

- **oom-protection** (`systemd-oomd`, picked today): **1.4 MB resident** (cgroup
  `MemoryCurrent`; 5.7 MB `VmRSS`). Ships with systemd — this is manager overhead for a
  facility already present, not a new daemon class. Zero boot, zero interactive. Bought:
  the swap-kill canary in `benchmarks/4.18` — kills the hog cgroup before the kernel
  OOM-killer thrashes the machine.
- **load-protection** (systemd slice weighting + core reservation, picked today): **0
  packages, 0 resident, 0 boot.** It is an invocation shape (`systemd-run --user -p
  CPUWeight=… -p AllowedCPUs=…`), not a service. Bought, in the 2a currency: kitty spawn
  under a saturating hog goes 504 ms → 149 ms, i.e. back to the 141.6 ms baseline.
- **disk-alert** (picked 2026-08-25): **0 resident**, a user timer firing 6x/day, nothing in
  any interactive path. **Healthy run re-measured 2026-08-26 after the rewrite: 8.7 ms ±
  0.8 (n=964, `bunne-test`)** — down from 3-6 s, because the three-meter version's `sudo`
  helper, `btrfs qgroup show` and `snapper list` are all gone. It is now one `df`. The
  caps it was the alarm on no longer exist (question 26), and everything it watched lives
  in the same btrfs pool as `/`, so one number sees all of it. Still a draft.
- **palette** (envsubst templater, picked today): **0 packages, 0 resident, 0 boot.**
  `envsubst` comes from `gettext`, a `base` dependency. Cost is 2.3 ms paid when the
  palette is edited, never at runtime. The rejected alternatives (`matugen` 13.1 ms,
  `wallust`) would each have added a package to do the same job less exactly.
- **kernel-boot-entries** (`limine-mkinitcpio-hook`, picked today): **0 resident, 0
  boot** — a pacman hook that runs only when a kernel is installed or removed.
- **docker** (base row written today): **0 resident until first use** — `docker.socket`
  enabled, `docker.service` not. The daemon's RAM is paid on the days Docker is used and
  not otherwise. `docker-compose` is a plugin binary that runs nothing until invoked.
- **editor deps** (`lazygit`, `ripgrep`, `fd`, added today): **0 resident** — all three
  are exec-and-exit binaries the editor shells out to. `ripgrep`/`fd` sit *inside* the
  2a path (they are what the file picker and find-in-files actually run), which is the
  argument for having them rather than against.
- **gpu-driver `nvidia-open-dkms` → `nvidia-open`**: no runtime delta — same module,
  prebuilt instead of locally compiled. What changes is update-time work (no rebuild per
  kernel bump) and one fewer dependency (`linux-headers`).
  **Applied on `bunne-test` 2026-08-25; no runtime delta was measured, and none of the
  figures first quoted here survive** (`benchmarks/4.24`, DA round same day). The idle
  power pair (8.71 W vs the dkms build's 9.25 W) was two single samples from different
  sessions and different post-boot ages with no interleaving — "within noise" was
  asserted without measuring noise. The boot pair was worse: there is no before/after at
  all, and userspace time cannot test a module-packaging change anyway. **No runtime
  number is claimed here, and none was expected** — the swap is an update-time change.
  What the bucket should record instead is the *cost* the row now owns: the prebuilt
  module is pinned to one kernel version, so a partial upgrade or an older snapshot's
  kernel means no module at all, where dkms rebuilt.

## 2026-08-25 evening — measured on `bunne-test`, not read off the desktop

- **snapshot boot entries: the 0-resident claim replicates on this machine.** *(Note the
  asymmetry this bucket exists to catch: the RAM half replicated in one command, and the
  latency half — how long that one-shot adds to `multi-user.target` — is still
  unmeasured. It is named again below rather than left to the RAM figure to cover.)* With
  `inotify-tools` absent, `limine-snapper-sync.service` logs *"inotifywait is not
  installed. Falling back to Snapper plugin integration."* and exits — `MainPID=0`,
  `MemoryCurrent=[not set]`, i.e. nothing in the resident bucket at all. The per-boot
  cost is that one short bash run on `multi-user.target`; **still unmeasured in
  milliseconds**, and it stays on the list until the acceptance run times it. Naming
  that gap rather than letting the RAM figure stand in for the answer is the
  measure-both-halves rule doing its job.
- **MUB sweep: −54 packages** removed from `bunne-test` (`benchmarks/4.24`). The only
  entry that touches this ledger is **`accountsservice`**, a D-Bus daemon that arrived
  as a `dms-shell` dependency and that nobody had chosen — the exact failure mode the
  resident-RAM bucket exists to catch. It was never rowed and never budgeted, which is
  worth noticing: a package pulled in as a dependency of a *trial* can install a daemon
  the ledger never sees. The rest (`hypr*`, `qt6-*`, `quickshell`, `xorg-xwayland`)
  cost nothing resident and are pure audit-surface removal.
- **Docker subvolume promotion: 0 runtime cost, by construction.** Two extra `/etc/fstab`
  lines mounting subvolumes off the device already mounted for `/` — no new daemon, no
  new device, nothing in any interactive path. The boot after the change completed with
  zero failed units. *(An earlier version of this line quoted that boot's
  `graphical.target` figure as "unchanged". It is a single boot with nothing to compare
  it against; the honest statement is that no boot cost was measured, and that the
  mechanism has no plausible route to one.)*

## Bucket: resident RAM — **marginal, not total**

**Budget: 600 MB of BunnE-attributable RAM. Currently ~371 MB (62%).**

Raised from 400 MB to 600 MB by the author 2026-08-21: *"we still want to minimize it, but 600MB is acceptable."* **Rule 6 still applies — headroom is not an allowance.** The 229 MB of slack exists so that a genuinely worthwhile feature is not blocked by an arbitrary line, not so that features may be added up to it.

**Restructured 2026-08-21 at the author's request**: *"It's not BunnE's fault
that ~500MB of RAM is taken by the firmware. The budget should be based on what
BunnE caused."* Correct in principle, and the measurement refines it.

### The floor — measured, and not budgeted

| Layer | Cost | Whose |
|---|---|---|
| firmware / iGPU reserved | **554 MB** | the hardware's |
| kernel structures (`SUnreclaim`+`KernelStack`+`PageTables`+`Percpu`) | 127.3 MB | any Linux |
| unavoidable init (systemd, journald, udevd, dbus-broker, logind) | 63.6 MB | any Linux |
| **bare Arch at a TTY, no desktop** (`benchmarks/2.1`) | **599 MB** | the baseline we budget *from* |

**One correction to the premise, because it changes the arithmetic:** the 554 MB
of firmware/iGPU reservation sits **outside `MemTotal`** — 16384 MB is installed,
`MemTotal` reads 15829 MB. It therefore **never appears in `free`'s used figure
at all** and was never inflating our number. It is recorded here because it is
worth knowing, not because it was ever counted against us.

The number that *does* matter is the **599 MB bare-Arch floor**, of which only
~191 MB is genuinely unavoidable (kernel + init). The remaining ~400 MB is btrfs,
zram, and the rest of the base install — *our* choices, but foundational ones
settled in Phase 2 and not re-opened per feature.

### What BunnE's desktop adds on top

| What we added | Where it lives | Why | Cost | Ledger |
|---|---|---|---|---|
| `niri` | package + `config/niri/config.kdl` | The compositor; there is no desktop without one. Hyprland cost **+266.6 MB** for the same job. | **115–172 MB** | `compositor` |
| `xdg-desktop-portal-gnome` | package + `portals.conf` | Screen sharing for meetings (C4). The lean `-wlr` alternative is output-only. | +45.6 MB | `portal` |
| `xdg-desktop-portal-gtk` | **unremovable dependency** | **Nobody chose it and it cannot be dropped** — required by `gtk4`, by `niri` itself, and by `xdg-desktop-portal-gnome`. | +32.2 MB | `portal` |
| `xdg-desktop-portal` | the frontend both backends need | — | +19.0 MB | `portal` |
| `mate-polkit` agent | `spawn-at-startup` | GUI privilege prompts; proven with `pkexec`. Grows to ~42 MB after showing a dialog. | +31.2 MB | `polkit-agent` |
| `wireplumber` + `pipewire` | socket-activated | Audio, Bluetooth included. 0 MB until first use. | +23.6 MB | `audio` |
| `gvfsd` | pulled in by the portal chain | **Nobody chose this** — portal → nautilus → gvfs. | +14.5 MB | — |
| `upowerd` | started by systemd, unasked | Battery status. `power-profiles-daemon` was dropped; this is a different package. | +13.9 MB | — |
| `mako` | D-Bus activated | Notifications; the disk alert depends on it. 0 MB until first fired. | +9.1 MB | `notifications` |
| `swaybg` | `spawn-at-startup` | Wallpaper; niri draws flat grey alone. **2.2 MB solid / 9.1 MB one image / 18.0 MB a different image per monitor** — see the note below. | **+2.2 MB** solid | `wallpaper` |
| `wl-paste --watch` | `spawn-at-startup` | Clipboard history. | +2.1 MB | `clipboard` |
| `swayidle` | `spawn-at-startup` | Lock on idle, DPMS off, lock before sleep. **Proven 2026-08-21**: lock on demand, lock on idle, and a playing video correctly prevents blanking. | **+3.3 MB** | `lock-idle` |
| `swaylock` | spawned by keybind / swayidle | Screen lock. **Zero resident when unlocked** — it only exists while the screen is locked. | **0 MB** | `lock-idle` |
| `waybar` | `spawn-at-startup` (niri) | The clock — day, time, date, ISO week — plus weather. **The single largest discretionary row in this bucket**, and the author bought it knowingly for the clock alone: it is the one thing on a bar with no keyboard equivalent worth having. **The GTK3 runtime is ~95% of the number**: five static modules measure 28.4 MB and the author's Omarchy bar with three extra polling modules measures 29.8 MB, so trimming the module list is not a lever (~1.4 MB). Measured on `bunne-test` in the live niri session, 2026-08-26. | **+28.4 MB** | `status-bar` |
| **Marginal total** | | | **~371 MB** | |

**The weather poll is the one recurring cost this bucket cannot express, so it is stated
here.** `custom/weather` is not resident — waybar forks `config/waybar/weather` on an
interval — but it is a `curl` and a shell **96 times a day**, plus 96 HTTPS requests to
wttr.in. That is the shape `disk-alert` already has in this bucket (0 resident, a timer
firing 6×/day), and the number is deliberate: Omarchy's equivalent module runs at 60 s,
i.e. **1440 a day**, for data that refreshes about hourly. Nothing waits at the keyboard for
any of it. **One poll a day costs more than the rest**: the first one after boot races
NetworkManager writing `/etc/resolv.conf`, so the script retries in a loop and can take ~25 s
before giving up on a genuinely offline machine. That is a background process nothing is
waiting on, and it is what stops the bar reading `weather n/a` for the fifteen minutes after
every boot. Row: `status-bar`.

### Fresh-install cross-check, 2026-08-24 (arch-bunny, overnight session)

Full PSS tables from 3 clean boots live in `benchmarks/4.2.arch-vs-nixos.md`.
Not folded into the table above because the accounting differs (whole-system
PSS-sum vs marginal-over-baseline) — but two rows deserve a re-measure on the
fresh box before Phase 4 trusts them:

- **The portal chain (96.8 MB across four rows above) was not resident at
  all on the fresh install** — nothing had D-Bus-activated it yet (gvfsd
  alone ran, 4.7 MB PSS). The old box's resident portal stack may be the
  post-first-screenshare steady state, not the boot state. If so, the real
  marginal cost is "0 until first screen share, ~97 MB after" — a very
  different row.
- **swaybg with a solid color is 2.2 MB PSS**, not 8.2. **2026-08-25: most likely RSS of the
  solid-colour case** — `bunne-test` measures **8.1 MB RSS / 2.2 MB PSS**, so 8.2
  is consistent with an RSS reading predating the 2026-08-21 use-PSS-not-RSS
  correction below. **Not proof** (DA round 19): the original was taken on a
  different machine in a different session and the original command was never
  recovered, so a 0.1 MB agreement across two machines is suggestive, not
  identification. Also on the table:
  niri 26.04 may render the backdrop color natively, making swaybg deletable —
  verification queued (`docs/research/ricing-cost-audit-2026-08-24.md`).

  Full scale, measured the same night on two 1920x1080 outputs (`benchmarks/4.25`
  deployed the assets; `CHOICES.md` `wallpaper` carries the decision):

  | swaybg mode | PSS | RSS |
  |---|---|---|
  | solid `-c #0f0f0f` | **2.2 MB** | 8.1 MB |
  | one image on both outputs (`-o '*'`) | **9.1 MB** | 17.6 MB |
  | a different image per output | **18.0 MB** | 26.6 MB |

  **These are steady, not cold readings** (checked 2026-08-26 after DA round 19 flagged
  them as single samples taken 2–3 s after start): sampling each mode at **3 s, 30 s and
  120 s** gives the identical figure every time — 2.2/2.2/2.2, 9.1/9.1/9.1, 18.0/18.0/18.0.
  swaybg does not release its decode buffers later, so a cold sample is the steady number.

  So real wallpapers cost **+6.9 MB PSS** over solid, and wanting a *different*
  one per monitor costs **+8.9 MB more again** — the decoded buffer is per output,
  not shared. Both are priority-3 spends against priority 2b and the author should
  see the number before it is treated as settled. **At 4K the buffers are 4x the
  pixels**, so a 4K dual-head setup is expected to be far worse and is unmeasured
  — do not extrapolate these figures to it.

Whole-desktop PSS-sum at idle, fresh install, 3 boots: **199-202 MB** —
comfortably consistent with the marginal table once the dormant portal
chain is accounted for.

### Methodology trap, 2026-08-26 — `systemd-analyze` cannot see the bootloader menu

Limine populates the systemd-boot loader-interface EFI variables, so `systemd-analyze`
prints an authoritative-looking `loader` figure. **It does not include the menu wait.**
Across a change that really costs 2 s (`timeout: 1` → `timeout: 3`, measured in
`benchmarks/4.28`), the `loader` figure moved **3.355 s → 3.359 s**. Anyone budgeting
bootloader cost from `systemd-analyze` would conclude the menu timeout is free. Measure
the **shutdown → next-kernel-start gap** from the journal instead — the same instrument
that diagnosed the 56-minute menu hang in `4.24`.

### Methodology correction, 2026-08-21 — use PSS, not RSS

**Every per-process figure in the table above is RSS, and summing RSS is wrong.**
A shared library page mapped by ten processes is counted ten times. Measured on
the live session:

| metric | total |
|---|---|
| sum of all process **RSS** | **610 MB** |
| sum of all process **PSS** | **389 MB** |
| overcount | **221 MB (36%)** |
| `free -m` used | **796 MB** |

**PSS** (proportional set size) divides each shared page by the number of
processes mapping it, so it sums honestly. `free -m` used is higher than either
because it also includes kernel structures that belong to no process.

**Read the rows above as upper bounds until re-measured with PSS.** Spot checks
show how far off they are: `polkit-mate` is 31.7 MB RSS but **12.1 MB PSS**;
`xdg-desktop-portal-gtk` is 31.6 RSS but **12.3 PSS**; `gvfsd` is 14.3 RSS but
**4.3 PSS**. The unremovable GTK portal costs a third of what was recorded.

**niri is the exception and the thing to watch.** RSS 298 MB, **PSS 284 MB** —
almost nothing of it shared — but **`RssAnon` is only 46 MB**. So ~238 MB is
file-backed and largely private: GPU buffers mapped through DRM, shader caches,
fonts. On an integrated GPU that *is* system RAM, so it counts; but it is a
different thing from a heap leak and must not be read as one.

**RESOLVED 2026-08-21 — not a leak; no action needed.**
[`benchmarks/3.6`](benchmarks/3.6.session-residents.md) carries the full chase.
Short version: **niri's own heap is 30 MB**, and 241 MB of the 305 is shared
libraries — `libLLVM` 85 MB, `libnvidia-gpucomp` 69 MB, `libgallium` 42 MB,
`libnvidia-eglcore` 21 MB — paging in lazily as code paths run. Bounded.
`RssFile` was constant at `257880 kB` across every sample. The 8.7 MB
sample-to-sample rise was the **swaylock lock surface** in `/dev/shm`, and
unlocking took `RssShmem` from 8172 kB to **12 kB** — fully reclaimed.
**But treat this row as an overstatement for the real target**: 90 MB of it is
NVIDIA libraries that do no work here (`fdinfo` shows `driver=i915`, 10.8 s of
render time, NVIDIA engines at 0 ns) and exist only because glvnd dlopens every
vendor. On the NVIDIA-only desktop they do the actual rendering. **Re-measure
niri on the desktop in Phase 6 before budgeting from this number.**

*(Superseded note, kept for the method:)* **Growth was sampled, not guessed.** niri measured 115 MB early, 172 MB
later in the same session, and 305 MB in a *fresh* 20-minute session — so window
churn is not the whole story. `~/t-niri-rss` on `bunne-test` samples RSS, RssAnon
and RssFile every 5 minutes to answer one question: **is the growth bounded (a
working set that plateaus) or unbounded (a leak)?** Do not re-budget this bucket
until that has an answer — niri is the largest single item in it.

### Two measurement caveats that bite this bucket

**1. Compositor RSS is history-dependent, not a constant.** `niri` measured
**115 MB** early in a session and **172 MB** in the same session after ~50
terminal windows had been spawned and closed by benchmarking. That is a **+57 MB
swing from window churn alone**. Any future RAM figure must state the session's
age and what has been run in it, or it is not comparable.

**2. `[preferred] default=` does not prevent a backend from starting.** Setting
`portals.conf` to `default=gnome` dropped `xdg-desktop-portal-gtk` and appeared
to free 30 MB — **it came back 12 minutes later**, because the setting only sets
*priority*; when an app requests an interface GNOME lacks (`Email`, `Inhibit`),
the frontend starts whatever backend provides it. And it cannot be uninstalled:
`gtk4`, `niri` and `xdg-desktop-portal-gnome` all require it. **The 30 MB is not
recoverable.**

## Rejected on cost — what we did not buy

Kept so the same ideas are not re-proposed, and so the budget is read as a set of
choices rather than a set of givens.

| Rejected | Would have cost | Instead |
|---|---|---|
| `starship` | 35–43 ms/prompt | hand-rolled `PS1`, 8.4 ms |
| `mise` (any mode) | 143 ms/terminal activated, 0.75 ms shimmed | Arch `nodejs` on `PATH`, **0 ms** |
| ungated `direnv` hook | 15 ms/prompt | gated on `$PWD`, 0.23 ms |
| `core.fsmonitor` | a resident daemon **per repo** | `core.untrackedCache`, no daemon |
| `walker` + `elephant` | a permanent launcher daemon | `fuzzel`, no daemon |
| Quickshell / ags / eww | a resident desktop shell | keybinds |
| a status bar | a permanently resident renderer | on-demand keybinds |
| `polkit-gnome` | archived upstream at 0.105 (2012) | `mate-polkit`, same 1 package, maintained |
| `xdg-desktop-portal-gtk` | 30.1 MB for `Email` + `Inhibit` | `default=gnome` alone; screen sharing unaffected |
| `codex`, `gemini`, `copilot`, `opencode` | four npm CLIs + their node dependency | `claude` alone, a native binary |
| `aws-cdk` (global npm) | installed, zero uses in shell history | not carried forward |

## Review triggers

Revisit the whole budget when any of these fire:

- **Any bucket exceeds its budget.**
- **The author notices slowness without being told to look for it.** That is the
  real acceptance test; the numbers exist to explain it, not to overrule it.
- **Before Phase 6** — the desktop is the daily driver and has 64 GB, but it also
  runs ML training, so headroom there is not what it looks like.
- **On a mature machine**, since two costs here grow with use: `vapoursynth`
  scales with `site-packages`, and git-based prompt costs scale with `.gitignore`
  style.

## Open re-investigation: `vapoursynth`

**Flagged by the author 2026-08-21** — *"I'm not convinced it's both unnecessary
and unremovable without a horrific hack, and it's a very expensive part of our
session login."* That scepticism is reasonable: it is **79% of the per-login
bucket** (64 ms of ~81 ms on a fresh machine, 460 ms on his four-year-old one)
and buys nothing anyone chose.

What was actually established, and what was not:

| Established | Not established |
|---|---|
| `pacman -Rp vapoursynth` fails — hard dep of `ffmpeg` **and** `mpv` | whether any Arch `ffmpeg` variant exists without `--enable-vapoursynth` |
| **Nothing links `libvapoursynth`** — not ffmpeg, not libavformat, not mpv | whether the declared dependency is therefore simply wrong, and reportable |
| `NoExtract` works but hides a file from a package that still owns it | whether a *documented, visible* mechanism exists that NoExtract's invisibility does not |
| The script forks a Python binary to print a constant path | what actually breaks if `VSSCRIPT_PATH` is merely unset — never tested |

**Do before re-deciding**, none of which was done: test whether anything at all
misbehaves with `VSSCRIPT_PATH` unset; check whether a fresh BunnE install even
pulls `vapoursynth` in, given `bunne-test` got `ffmpeg` via the portal chain
rather than via `mpv`; and file the upstream Arch report, since an over-declared
dependency plus a forking `profile.d` script is a packaging bug whose fix helps
everyone. `CHOICES.md` `shell-startup` is `rejected` **for the NoExtract
approach specifically** — not for the problem, which stands open.

**INVESTIGATED 2026-08-24 on the fresh install — every open question answered:**

1. **`VSSCRIPT_PATH` is read by nothing on the system** except vapoursynth's
   own Python package (`_shell.py`/`_utils.py` — its own tooling finding
   itself). Grepped every `libav*`/`ffmpeg` binary: zero references.
2. **The ffmpeg dependency is real, but not via the env var.** `ffmpeg` is
   built `--enable-vapoursynth` and `libavformat` **dlopens
   `libvapoursynth-script.so` by soname** (no ldd linkage — string reference
   confirmed), resolved through `/usr/lib/libvapoursynth-script.so`, a
   symlink into site-packages. So the *package* dependency is legitimate
   (the .vpy demuxer needs the lib on disk); "nothing links it" was true of
   ld-time linkage only.
3. **Nothing misbehaves with the variable unset** — proven, not inferred:
   `env -u VSSCRIPT_PATH ffmpeg -f vapoursynth -i /nonexistent.vpy` loads
   the demuxer fine and fails only on the missing file; a normal encode
   also runs clean.
4. **Fresh BunnE does pull it in**: `ffmpeg → vapoursynth`, install reason
   "dependency," on the 2026-08-23 install.
5. **Cost re-measured on the fresh box**: 66–83 ms per login shell (bash
   `time`, 5 runs, idle) — a full Python interpreter start
   (`/usr/bin/vapoursynth` is a Python script) to compute a path nothing
   uses.

**Verdict:** the *file* is a pure waste; the *package* must stay. The cost
sits in the per-login bucket only (autologin at boot + ssh sessions —
kitty spawns non-login shells), so "leave it alone" still holds locally.
**The correct fix is the upstream Arch bug report** — `profile.d` script
exports a variable consumed by nothing external, costing every Arch user a
Python fork per login; the demuxer provably works without it. Filing was declined by the author
(2026-08-24) — no upstream report; the file stays, accepted as a known
per-login cost. Investigation CLOSED.
