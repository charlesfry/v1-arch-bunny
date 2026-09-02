# Open questions — the author's desk

**The one queue.** Questions used to be numbered in whichever morning report
raised them and answered in whichever decision-prep doc worked them up, which
meant "question #5" existed in two files and neither was the list. This file is
the list; the numbers are stable, the evidence is linked, and answered items move
to the bottom rather than disappearing.

Numbers 1–14 keep the numbering from
[`morning-report-2026-08-25.md`](morning-report-2026-08-25.md); 15+ were raised
after it.

**How to answer fast:** reply with the numbers you want changed. Anything you
don't name gets applied as *Recommended*.

---

## Open

### 21 · MegaUltraBunny, later (new — parked at the author's word)
**Author, 2026-08-25:** *"let's get rid of the packages for now and come back to MUB
later… I don't want MUB installing a ton of crap that only gets used with its theme.
A few packages is fine, but I don't want to compromise the integrity of the
non-meme machine."* Recorded as a standing constraint in
[`megaultrabunny-research.md`](megaultrabunny-research.md): MUB may cost a *few*
packages, and it may never cost the base machine's integrity. The nine measured
prototypes and their numbers survive; the packages do not. Nothing to decide until
the base rice is done.

---

## Answered

Applied to `CHOICES.md` unless noted. Dates are the day the author answered.

**2026-08-26**

- **28 · Is btrfs qgroup accounting worth keeping now that it enforces nothing?** →
  **keep it.** Author confirmed after the nuance was restated: accounting is not paid
  for a notification line, it is what snapper's `SPACE_LIMIT`/`FREE_LIMIT` space-aware
  cleanup actually runs on — dropping it would fall back to `NUMBER_LIMIT` alone
  (count-based retention, no space awareness), touching gripe #2. `docker-storage-quota`
  and `snapshot-system` already reflect this (quota on, no limit); no ledger edit
  needed. Cost stated in `BUDGET.md`'s per-snapshot-deletion bucket rather than left
  silent. Rows: `docker-storage-quota`, `snapshot-system`, `disk-alert`.

Answering 26 left `btrfs quota` **enabled** with no limits set, and the stated justification
was that `disk-alert`'s meter 2 reads it. That looked like a per-write tax paid for one line
in a notification, so it got measured: loopback btrfs, `bunne-test`'s real 24-snapshot
shape, a 6457-file `pacman` package as the workload, n=9 per arm, arms alternating.

| operation | quota off | quota on | Δ |
|---|---|---|---|
| extract 6457 files | 0.591 s | 0.600 s | **no effect established** — the ranges overlap |
| `rm -rf` them | 0.236 s | 0.271 s | +0.035 s |
| `subvolume snapshot` | 0.031 s | 0.053 s | +0.022 s |
| **`subvolume delete`** | **0.008 s each** | **0.355 s each** | **+0.347 s, 46×** |

So the cost is real, essentially all of it is in **snapshot deletion**, and that is what
snapper does on cleanup (`NUMBER_LIMIT=2-15`). Nothing waits on it at the keyboard — but
btrfs transaction commits are filesystem-wide, so ~1.8 s of commit is ~1.8 s in which every
other writer to `/` waits. Recorded in `BUDGET.md` as a new bucket, *per snapshot deletion*,
because none of the existing buckets fits and an uncounted cost is how a machine gets slow
one imperceptible feature at a time.

**Then the premise collapsed.** From `man 5 snapper-configs` on the machine: `QGROUP` is
*"the btrfs quota group used for **space aware cleanup algorithms**"*, and
`/etc/snapper/configs/root` carries `SPACE_LIMIT="0.08"` and `FREE_LIMIT="0.2"`. Both are
space-aware, so **both run on that qgroup.** The quotas are not paid for a notification
number; they are what snapper's space-based retention runs on — part of gripe #2's fix.
Option 3 above ("disable quotas, read `du` instead") therefore does not work as written:
`du` can replace the *meter*, and nothing in userspace can replace what snapper reads.

**Recommended: option 1 — keep it, cost now stated instead of silent**, which is what
`CLAUDE.md` asks of a trade like this. The honest sentence is: *snapshot deletion costs
~0.35 s per snapshot instead of ~0.008 s, paid on snapper's cleanup timer, and it buys
space-aware retention plus two of the alert's three meters.* Say no if you would rather have
`NUMBER_LIMIT` alone doing retention and no space awareness at all — that is the actual
trade, and it is a fair thing to want.

**Two side-findings worth your eye, both already applied:**
- **Meter 3 had the same silent-blindness bug meter 2 had.** With quotas off, `excl` comes
  back empty and the meter just `continue`d — so snapper's retention would have quietly
  stopped working *and* the alert would have reported a healthy machine. It is now a loud
  breach naming the cause. Tested.
- **The first version of the deletion measurement was wrong in a way worth remembering.**
  `btrfs subvolume delete` + `btrfs subvolume sync` reported 28-30 s in *both* arms. The
  delete returns in 0.02 s and the subvolumes leave the list in 0.04 s; `subvolume sync` then
  blocks a flat ~29 s regardless, so the arm was measuring the tool. `delete -C` is the
  honest instrument. A figure identical across both arms of a controlled test is evidence the
  instrument is broken, not evidence the effect is absent.

Rows: `docker-storage-quota`, `snapshot-system`, `disk-alert`.

### 21 · MegaUltraBunny, later (new — parked at the author's word)
**Author, 2026-08-25:** *"let's get rid of the packages for now and come back to MUB
later… I don't want MUB installing a ton of crap that only gets used with its theme.
A few packages is fine, but I don't want to compromise the integrity of the
non-meme machine."* Recorded as a standing constraint in
[`megaultrabunny-research.md`](megaultrabunny-research.md): MUB may cost a *few*
packages, and it may never cost the base machine's integrity. The nine measured
prototypes and their numbers survive; the packages do not. Nothing to decide until
the base rice is done.

---

## Answered

Applied to `CHOICES.md` unless noted. Dates are the day the author answered.

**2026-08-26**

- **27 · Where does non-XDG config live in the repo?** → **nowhere; `install.sh` writes
  them, and the layout question is not answered because it no longer has to be.** Author:
  *"i like your suggestion."* All six §2 files become installer lines rather than tracked
  files: `zram-generator.conf` is 28 bytes, `/etc/conf.d/snapper` is one line,
  `/etc/default/limine` is one setting, the `getty@tty1` drop-in contains the username so
  it must be generated anyway, `/etc/snapper/configs/root` is five of our values inside
  1238 bytes of upstream defaults (→ five `snapper set-config` calls), and
  `.bashrc`/`.bash_profile` are separately `deferred` pending the shell review and so are
  not harvestable at all today. `config/` keeps its README as written — `$XDG_CONFIG_HOME`
  and nothing else. **The question re-opens the day a file genuinely wants tracking**, and
  the likely trigger is named: the shell config, once reviewed. Same shape as
  `install-artifact` — dissolved by the work rather than settled. Rows:
  `dotfile-deployment`. Detail: `phase4-config-inventory.md` §7.

- **26 · The Docker qgroup cap can take the whole machine read-only** → **option 4: drop
  the caps, keep the qgroups for accounting.** `btrfs qgroup limit none` on `@containerd`
  (was 100 GiB) and `@dockervol` (was 50 GiB); the subvolumes, their top-level placement
  and their fstab mounts are untouched, so `snapshot-bloat` is unaffected — Docker stays
  out of every snapshot of `@` because of the subvolume boundary, never because of the
  limit. The reasoning that makes this a priority-1 win: gripe #1's real shape is *slow*
  growth, and against slow growth a 6×/day alert is a good instrument; what the limit
  added on top was a *new* priority-1 failure mode the gripe never had (ENOSPC to one
  process vs. the whole filesystem read-only until reboot).
  **The answer's load-bearing claim was tested rather than assumed** — quota accounting
  with **no limit** is safe: verity ENABLED and the fs `rw` 3/3, against the tight-limit
  control's forced-readonly 1/1, same box and session (`benchmarks/4.27`, new
  `--accounting` arm). A real `docker pull` then ran clean against the uncapped subvolume.
  **`disk-alert` had to change to survive this** — its meter 2 selected qgroups *carrying a
  cap*, so it would have silently monitored nothing; the 100/50 GiB figures are now
  thresholds in that script, a missing watched subvolume is itself a breach, and all four
  states are tested. Opened **28** on the way out. Rows: `docker-storage-quota`,
  `snapshot-bloat`, `disk-alert`.

**2026-08-25**

- **12 · greetd vs getty-autologin** → **getty-autologin; greetd removed.** Author, after
  driving it: *"greetd did nothing that seemed worthy of keeping. I just saw a tty… let's
  get rid of it."* The drive nearly did not happen because `initial_session` boots straight
  into niri and the greeter only appears **on logout** — a silent boot reads as nothing to
  test. What he eventually saw was `agreety`, a bare text login, which is an easy no at
  6.8 MB PSS forever. Disabled, `getty@tty1` re-enabled, `pacman -Rns greetd`, `/etc/greetd`
  gone, two reboots verified (niri up, zero failed units, boot a wash at 17.658 s vs
  17.344 s). Row: `display-manager`, now **picked**.

- **22 · Limine menu timeout** → **`timeout: 3`**. The author took the 3-second middle
  against leaving it at 1: priority 1 outranks 2a, and one second is catchable only when
  you are expecting it. Applied to `/boot/limine.conf` on `bunne-test` and validated with
  `scripts/check-limine.sh`, and **timed and confirmed** in `benchmarks/4.28` — 16 s median
  at `timeout: 1` vs 18 s at `timeout: 3`, n=3 per arm, Δ exactly 2 s. So the three-second
  window is real and costs 2 s on every boot. Read from limine's own `CONFIG.md` while applying it: `timeout` takes decimal
  values such as `0.25`, `timeout: no` disables automatic boot entirely, and `0` boots the
  default instantly — so the "no window at all" note above is confirmed. Rows:
  `snapshot-boot-entries`, `kernel-boot-entries`.
- **23 · Snapshot rollback acceptance test** → **PASSED, 2026-08-25 evening.**
  `benchmarks/4.25.rollback-acceptance.md`. `@` moved from subvolume ID 256 to 353 with
  `Parent UUID` equal to snapshot 97's, the canary was gone, and Docker survived. **Two
  legs remain unproven** — the way back, and the GUI restore gesture — and four priority-1
  defects in the recovery path are recorded there. Row: `snapshot-boot-entries`.
- **24 · `hash_mismatch_panic`** → **`no`**, following the desktop. Keeps the machine
  bootable after an interrupted pacman transaction; snapshots already cover tampering.
  Applied to `/boot/limine.conf` on `bunne-test`. **Verified it will actually take
  effect:** `CONFIG.md` line 119 says the option is *forced to `yes` when Secure Boot is
  active*, and `bootctl status` reports Secure Boot **disabled** on this machine — so
  enabling Secure Boot later would silently revert this decision. Rows:
  `snapshot-boot-entries`, `kernel-boot-entries`.
- **25 · Screenshot cancel path** → **guard the bind.** Now
  `sel=$(slurp) || exit 0; grim -g "$sel" - | satty -f -`, so Escape during the drag is a
  clean no-op rather than a silent failure through grim and satty. In
  `config/niri/config.kdl`, deployed to `bunne-test`, `niri validate` clean, and both
  branches tested under `sh -c` (cancel exits 0 silently; success passes the region
  through). Row: `screenshot`.

- **1 · Font delivery** → vendor the two OFL TTFs in `assets/fonts/` with the
  license file; installer symlinks them and runs `fc-cache -f`. `google-fonts`
  megapackage and curl-at-install both rejected. Row: `font`. **Vendored 2026-08-25**
  — and the box's mystery unowned files turn out **byte-identical to the Google Fonts
  release**, so nothing that was measured changed. OFL 1.1 confirmed from the TTFs'
  own name table, not assumed.
- **2 · Vendor-conditional `Packages` cells** → the column lists only what installs
  on *every* BunnE machine; conditionals move to installer logic keyed on detected
  hardware and are described in the Note. Applied to four rows (`gpu-driver`,
  `firmware-set`, `microcode`, `jupyter-in-neovim`); the generated package list is
  now free of prose.
- **3 · Status-cell bolding** → normalize. 11 cells de-bolded; niri and kitty now
  appear in the generated list.
- **4 · satty keybind** → `Mod+Print { spawn-sh "grim -g \"$(slurp)\" - | satty -f
  -"; }`. *(satty is the annotation editor — the thing that opens on a fresh
  screenshot so you can draw an arrow on it before pasting. It was installed and
  bound to nothing, which is why the question existed.)* Row: `screenshot`. **In the
  config and proven end-to-end 2026-08-25** — satty opens on the piped grim image at
  the right geometry, clipboard round-trip byte-identical; the draw-and-export half
  needs a person (`benchmarks/4.24`).
- **5 · docker base row** → written, socket-activated (`docker.socket` enabled,
  `docker.service` not), `docker-compose` plugin included, user added to the
  `docker` group by the installer. *(The question was only "does the ledger say we
  install Docker at all" — it never did, so a generated installer would have
  shipped a machine with the storage caps but no Docker. The sub-question was
  whether to also ship compose, the tool that runs a multi-container stack from a
  YAML file; it runs nothing until called, so yes.)* Row: `docker`.
- **6 · LICENSE** → MIT, `Copyright (c) 2026 Charles Fry`.
- **7 · `nvidia-open-dkms` → `nvidia-open`** → switch. Drops `linux-headers` and
  the per-kernel-bump rebuild. Row: `gpu-driver`. **Done and reboot-verified
  2026-08-25**: same driver version either side (610.57.04), `dkms`/`linux-headers`/
  `pahole` orphaned and removed, idle P8 8.71 W, 3.06 s to `graphical.target`.
- **8 · fzf / lazygit** → `lazygit` in, `fzf` out (verified: snacks.picker never
  spawns the `fzf` binary). Row: `editor`. See 20 for the shell half.
- **9 · oom / load protection** → both ratified as drafted, both now `picked` with
  their exercised mechanisms recorded. Rows: `oom-protection`, `load-protection`.
- **10 · Editor draft +33 ms** → re-affirmed; `markdownlint` and `markdown-preview`
  stay the named trim candidates. Row: `editor`.
- **11 · Upstream bug reports** → **don't file** (author). The niri
  `Handled`-while-locked reply and molten's `:e`-reload destruction stay recorded in
  `benchmarks/4.15` and the `jupyter-in-neovim` row, with the diagnostic one-liner
  (`pgrep -x swaylock` — corrected from `-f`, which always answers "locked"
  because swayidle's arguments contain the string), so a future reader is not
  re-debugging them from scratch.
- **13 · playerctl / orca keybinds** → nothing to decide; playerctl is installed and
  rowed, the orca "bind" was only ever a comment.
- **14 · Palette mechanism** → the `envsubst` templater. *(The three candidates were
  material-you palette generators — `matugen` and `wallust` derive a color scheme
  from a wallpaper image — versus five lines of `envsubst` rendering config
  templates from one hand-written palette file. The generators **toned** hand-picked
  colors instead of passing them through, under every config syntax tried, which
  disqualifies them for a hand-designed matte-black-and-neon palette. envsubst is
  exact, 2.3 ms, and installs nothing: it comes from `gettext`, a `base`
  dependency.)* Row: `palette`, new.
- **15 · `ripgrep` + `fd`** → added. System-PATH binaries the picker and `gr` shell
  out to; silently degrade without them. Row: `editor`.
- **16 · MUB keep-or-sweep** → **sweep all of them** (author). See 21. **Done on the
  box 2026-08-25**: −54 packages, taking the whole `hypr*`/`qt6`/`quickshell` stack,
  `accountsservice` and `xorg-xwayland` with them; `hypr*` count 0, orphans 0, niri
  session untouched (`benchmarks/4.24`).
- **17 · Docker subvolumes at the top level** → ratified. `@containerd` and
  `@dockervol` become top-level subvolumes mounted from `/etc/fstab` like `@home`,
  so the caps and the snapshot exclusion survive a rollback. Row:
  `docker-storage-quota`. **Done and reboot-verified 2026-08-25** — both promoted to
  `top level 5`, mounted from fstab, caps re-applied and re-proven with an
  incompressible-data canary (`benchmarks/4.24`).
- **18 · `limine-mkinitcpio-hook`** → take it. Same publisher, same pinned key;
  stops `limine.conf` drifting after a kernel change. Row: `kernel-boot-entries`,
  new.
- **19 · Disk-alert design** → ratified as drafted (threshold 80%, three meters,
  root-owned read-only qgroup helper, missing helper counts as a breach). Row:
  `disk-alert`, new.
- **20 · `fzf` for bash `Ctrl-R`** → **no** (author). `fzf` is now out of BunnE
  entirely — not an editor dependency and not a shell one. Recorded in the `editor`
  row so it does not get re-litigated as "surely the picker needs it".
- **Snapshot boot entries** (was `blocked`) → trust Omarchy's repo for the compiled
  binary, and *"I don't want a half-baked snapshot system."* Row rewritten to
  `picked`, with the publisher key pinned by fingerprint instead of `TrustAll`.
