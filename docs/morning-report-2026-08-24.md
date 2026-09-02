# Morning report — overnight session of 2026-08-23 → 24

Written for the author waking up. Everything here is either DA-gated (see
`benchmarks/DA-TALLY.md`) or explicitly labeled provisional. Raw logs live on
`arch-bunny` under `~/log/`, copies in the session scratchpad, extracts in
`benchmarks/`.

## TL;DR

- **Arch is installed and boots unattended** on p5/p7; NixOS untouched and
  still the firmware default. Snapshot byte-cap is live and canary-proven
  (DA round 2: survives with caveats). One config item needs your
  ratification: `NUMBER_LIMIT="0-15"` (floor 0 — see `CHOICES.md`
  `snapshot-system`).
- **Bake-off, same instruments, same hardware, DA-supervised** (§3):
  kitty 130 vs 153-155 ms warm; fuzzel dead equal (the control);
  desktop-ready 10-11 s vs 15-17 s; boots 16.8-17.7 s vs 24.3-26.4 s as
  configured; RAM totals are workload-dominated on the NixOS side
  (Electron 455 MB!) — like-for-like session subset ~200 vs ~273 MB.
  Explicitly does NOT close `os-base`.
- **kitty launch** (§4): target beaten — 130 ms on Arch (NixOS 153-155),
  and 130 ms is kitty's intrinsic floor here; config/fonts cost zero; the
  only bigger lever is the banned single-instance family. Terminal ordering
  from 3.7 re-verified exactly; kitty RAM corrected to 75 MB PSS (old
  "297 MB" was RSS).
- **Best 2a find of the night: kitty's `input_delay`** — the input
  round-trip is 3.6 ms by default and **0.53 ms with `input_delay 0`**
  (`benchmarks/4.6.inputrt.md`): a 7× cut on the keystroke path, bigger
  than anything the kernel choice moves (zen measured null on both spawn
  and input-rt). Candidate 4th line for kitty.conf — your call (trade:
  more input wakeups, battery cost unmeasured).
- **Gripe #1 (docker disk cap): a write was actually refused** — the
  mechanism works, with two shipping-killer traps found and documented
  (§ queue item 7, `benchmarks/4.5.docker-quota.md`); snapshot exclusion
  of docker bytes proven too.
- **Research**: `docs/research-arch-dotfiles-2026-08-24.md` (repo survey ×13
  + implications) and `docs/research/ricing-cost-audit-2026-08-24.md`
  (techniques priced against Fast/Light). One candidate already
  refuted-by-test tonight: niri cannot natively paint the workspace
  background on 26.04 — swaybg stays, pixel-proven.

## 0. Box state as you wake up

The laptop is running **Arch (mainline kernel)** with the niri desktop up.
`BootOrder` still puts **NixOS first**, so a plain reboot lands in NixOS —
boot Arch via the firmware menu (`Arch Linux`), or from NixOS:
`sudo nix-shell -p efibootmgr --run "efibootmgr --bootnext 0000" && sudo reboot`.
From Arch, `sudo efibootmgr --bootnext 0000` before any reboot keeps you on
Arch. linux-zen is installed alongside (limine menu entry, non-default).
The screen may be locked (swaylock, 15-min idle) — your normal password.
Bluetooth is enabled (end-of-night trial); docker is socket-activated with
the capped containerd subvolume live (2 GiB test limit).

## 1. Install (done, verified)

Signed bootstrap (sig checked against the archlinux.org-pinned key) →
pacstrap from NixOS over SSH → LUKS2+btrfs (@ @home @log @pkg @snapshots,
noatime,compress=zstd:1) → limine on p5 only → linux mainline + intel-ucode +
firmware splits (iwlwifi ucode verified present before reboot) → zram ram/2 →
NetworkManager (wifi profile carried over) → snapper+snap-pac capped →
niri/kitty/fuzzel desktop from `config/` via symlinks → autologin to
niri-session. First boot came up over wifi+ssh with zero hands.

Deviations added for unattended work (undo before Phase 5): passwordless
sudo for `bunne`; LUKS keyfile in initramfs (`benchmark-unlock` shape);
`panic=30` on cmdline; sshd enabled (pre-existing deviation kept).

Two bugs found and fixed on the way, both worth keeping:

- **`.bash_profile` autologin guard must check interactivity** — an
  unconditional `exec niri-session` fork-loops through niri-session's own
  login-shell re-exec (~3 Hz forever, desktop never starts). Guard:
  `[[ $- == *i* && -z $WAYLAND_DISPLAY && $(tty) == /dev/tty1 ]]`.
- mkinitcpio 41 ships no fallback preset (`PRESETS=('default')`) — docs and
  muscle memory that assume `initramfs-linux-fallback.img` are stale.

## 2. Snapshot system (your #1 worry — it was justified)

Your hunch was right three ways: nothing ever took snapshots (no snapper row,
never installed in Phase 2); retention plans counted snapshots but capped no
bytes; and hourly timelines (the Omarchy bloat engine) would have been the
default. What's live now, all DA-gated in `benchmarks/4.1.snapshot-cap.md`:

- snap-pac pre/post pairs around every pacman transaction; **no timeline**.
- Byte cap ~20 GiB (`SPACE_LIMIT=0.08`) + keep-20%-free (`FREE_LIMIT=0.2`),
  via btrfs qgroup 1/0, enforced daily. Proven with 22 GiB of incompressible
  canaries at the production limit: oldest deleted first, stopped under the
  cap with history still alive, +22 GiB real free space verified.
- Error direction is over-deletion (safe for the disk, costs history).
  Named edges in the benchmark file; the DA transcripts are worth your read.
- **Ratify: floor 0** (`NUMBER_LIMIT="0-15"`). You approved 2-15; DA showed a
  nonzero floor exempts the newest N snapshots from the cap entirely.

## 3. Bake-off vs NixOS — same instruments, same hardware, same night

Full data with per-boot dispersion, warts, and raw logs:
`benchmarks/4.2.arch-vs-nixos.md` (+ `benchmarks/raw/`,
`benchmarks/instruments/`). DA round 1 rejected the first write-up
(rightly — mislabeled Ns among other sins); revision 2 answers every point
and **explicitly does not close the `os-base` row** — no thresholds were
pre-registered, so this is characterization, not verdict. Headlines:

| metric | Arch | NixOS |
|---|---|---|
| kitty warm median | 130.1-131.7 ms (4 boots) | 152.8 / 155.0 ms (2 boots) |
| kitty cold | 170-188 ms (4) | 249-273 ms (5) |
| fuzzel warm median | 20.9-21.5 ms | 21.9 / 22.4 ms — **equal: the control** |
| desktop-ready (niri.service, monotonic) | 10.0-11.1 s (4) | 15.3-17.2 s (4) |
| power-button→desktop (incl. measured loader waits) | ~17.5 s | ~27 s (≈4.8 s of that is systemd-boot's `timeout 5` vs limine's now-1 s) |
| session PSS, like-for-like subset | ~200 MB | ~273 MB (totals 854-858 MB are workload: Bitwarden-Electron 455 MB + Docker 126 MB) |

The fuzzel row is the interesting one: identical across OSes, which clears
the compositor/spawn path and pins the kitty delta on kitty's own bring-up
per OS. Second genuinely-open oddity the DA process surfaced: same-binary
niri idles ~13% heavier on NixOS at like samples (82.7 vs ~94 MB PSS), and
Arch's niri PSS decays ~7% within each boot while NixOS's is flat —
builds/kernels/GPU stacks all differ (nvidia-open there, firmware-less
nouveau here), so it's recorded as an open question, not a claim. Kernels differ (7.1.9 vs 6.18.44 — the kernel row's
"apples-to-apples" clause was wrong in detail; annotated). And the single
most useful RAM lesson for BunnE came from the NixOS side: **an idle
Electron app costs more than the entire desktop** (455 MB vs 200 MB) —
whatever password-manager story BunnE ships, it should not be a
resident Electron autostart.

## 4. kitty launch (your target: beat NixOS's ~170 ms, no single-instance hacks)

**Already beaten, and now characterized to the floor**
(`benchmarks/4.3.terminal-rerun.md`): Arch kitty is ~130 ms warm vs NixOS's
153-155 ms same-instrument (and the ~170 ms you remembered). The ~130 ms is
kitty-intrinsic on this hardware: our 3-line config costs zero
(`--config NONE` measured identical), fonts are not a factor (fc-match
6-10 ms cached), exec floor is 2 ms — the rest is embedded-Python + EGL +
Wayland bring-up. The only lever bigger than a few ms is the
single-instance/daemon family, which you banned (and foot's `--server` is
the same shape). Context from the 3.7 re-verification (ordering replicated
exactly on the new install/kernel/instrument): foot 33.9 ms but no kitty
graphics (C5), alacritty 94.7 ms ditto, **ghostty 305.7 ms warm / 1.3 s
cold** — the C5-capable alternative costs 2.3× kitty. kitty stays the right
pick; 130 ms is the honest price of the graphics protocol, and it is 15%
cheaper here than on the NixOS side. Also corrected: kitty's RAM is
**75 MB PSS** with a window open, not 3.7's "297 MB" (that was RSS).

## 5. Re-verification / methodology relitigation

Per your instruction: taste rows untouched; experiment-backed rows re-examined.

- **3.7/3.8 (terminal + spawn numbers) — methodology holds up, with three
  honest asterisks.** (1) They were taken on the dead install, almost
  certainly under linux-zen (the bootloader row's Measured column says zen
  was what booted); tonight runs mainline — so absolute ms don't transfer,
  ordering claims do. (2) 3.7's RAM column is **RSS**, which the project's
  own later rule (PSS, from the nix-bunne lessons) bans — kitty "297 MB" is
  the poster child, since GPU terminals' RSS counts shared graphics
  mappings; re-taken tonight as PSS (see 4.3). (3) 3.8's method section was
  actually good — the "Arch numbers, method unspecified" charge in
  nix-bunne's DA log round 1.7 is about how the numbers were *quoted across
  repos* without their method line, not about 3.8 itself. Lesson adopted:
  numbers quoted across repos carry their method line with them.
- **3.8's corrected kitty ~146 ms / fuzzel ~25 ms replicate** within
  kernel/install confounds as tonight's 130.2 / 21.1 ms medians (better
  instrument: raw socket, no 4 ms CLI correction needed, n=10 × 3 boots,
  loads recorded). Ordering and rough magnitudes confirmed; the old numbers
  were honest.
- **3.3 boot (17.406 s total on the old install) replicates** as
  16.8-17.7 s tonight on a different kernel and fresh install — same shape
  (keyfile unlock, sshd on). The old number was honest.
- **3.6 session residents**: fresh PSS tables collected each boot (mako
  correctly absent until first notification — the D-Bus-activation claim
  verified again on a fresh install; swaybg 2.2 MB; full table in 4.2).
- **Row 71 (vapoursynth profile.d "leave it alone")** got fresh evidence
  tonight: the file is back on the new box (ffmpeg dependency) and costs a
  python fork per login shell (~70 ms measured once; precise numbers in
  4.3). During the autologin fork-loop bug it was re-run ~3×/second — the
  original "leave it alone" reasoning (per-login ms) still holds, but the
  row should note the dependency arrives via ffmpeg and the cost recurs per
  login shell, not per boot.
- **4.1 (new): "prove it, don't infer it" caught two real things** the
  config-reading approach would have shipped broken: NUMBER_MIN_AGE silently
  nulls young-snapshot cleanup, and a nonzero NUMBER_LIMIT floor quietly
  exempts the newest snapshots from the byte cap.

## 6. Research: what the big rice repos do

See `docs/research-arch-dotfiles-2026-08-24.md`.

## 7. Queue for you (decisions only you can make)

1. Ratify `NUMBER_LIMIT="0-15"` (or pick a floor and accept that the newest
   N snapshots are exempt from the byte cap).
2. The `baseline` snapshot is outside the cap by design (no cleanup
   algorithm). Keep it pinned for the bake-off, or give it `-c number` and
   let it be expendable?
3. `network-stack` row: NM picked for bake-off symmetry; revisit iwd
   (~20 MB lighter resident) once the bake-off closes.
4. Test-box deviations to eventually undo: passwordless sudo, keyfile
   unlock, sshd enabled, `panic=30`.
5. ESP p1 orphan cleanup (~363 MB) still yours — classifier blocks it.
6. bluetooth.service: **enabled at the end of the night** (controller
   powered, bluetoothd 2.5 MB PSS — closes the bake-off asymmetry; the
   NixOS side reads 3.0). Pairing-level acceptance still yours.
7. **Gripe #1 broke open tonight** (`benchmarks/4.5.docker-quota.md`):
   a Docker write was **actually refused** by a qgroup-capped
   `/var/lib/containerd` subvolume — the row's own criterion — after two
   traps worth reading: the naive setup silently doesn't enforce (needs
   `btrfs quota rescan -w` after subvolume creation), and at the cap
   containerd wedges (deletes fail too; recovery = bump-clean-relimit,
   proven). Snapshot exclusion of the nested subvolume also proven (gripe
   #2's docker half). Rows updated with evidence, still yours to settle:
   cap size, whether `/var/lib/docker` (volumes!) gets a subvolume too,
   headroom-vs-recovery-doc. Docker left socket-activated (0 resident);
   the capped subvol is live with a 2 GiB test limit.
8. linux-zen: probed overnight (`benchmarks/4.4` — ~2-3% kitty spawn, n=2,
   verdict: doesn't displace mainline). It is still installed with a limine
   entry; keep for more samples or remove (a second initramfs per
   kernel-adjacent update while it stays).
9. **kitty `input_delay 0`**: ratify as kitty.conf line 4? (7× input-rt
   cut, unmeasured wakeup/battery trade — `benchmarks/4.6.inputrt.md`.)
10. nouveau is loaded on the unused dGPU with no firmware (can't reclock —
   likely idling hot). Blacklist on this box, or install the real driver
   (the NixOS side now runs nvidia-open, which is also a confound noted in
   4.2's niri/kitty deltas)? Your call.
