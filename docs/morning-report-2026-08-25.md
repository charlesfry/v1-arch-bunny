# Morning report — overnight session 2026-08-24 → 2026-08-25

Unattended overnight run per the author's instruction ("do as much work as
possible without me"). Everything below is committed and pushed in both
repos; every test conclusion cleared a DA round (nix rounds 14–17, plus
in-place corrections here). **Author decisions are batched at the bottom —
nothing there was decided unilaterally.**

## Headlines

1. **nix-bunne's #1 risk question now has data on both sides of the
   bake-off.** PyTorch/CUDA via uv replicated on NixOS (round 14; fresh
   boot, allclose-verified compute, autograd; `LD_LIBRARY_PATH` decomposed
   by A–D probes — the nix-ld bundle carries `import`, the driver path
   carries CUDA, both separately load-bearing) — and the **identical script
   on the Arch half passed with zero env configuration** (round 17;
   bare-env probe passes where NixOS's fails at import; **52.0 s wall from
   empty venv to verified GPU compute**, cold 2.3 GB download). The
   friction asymmetry is now a measured pair on identical hardware.
   Honest disclosure: the "never run" premise I started from was stale —
   round 8 ran the capability test on 08-22; tonight is filed as
   replication + strengthening (see the stale-premise pattern below).

2. **`nixos-rebuild switch` wall time — the "number nobody has" (round
   16):** no-op floor **~11.3 s** (n=4, spread <100 ms), first-of-session
   ~15 s, with-fetch ~19 s. Every NixOS config edit pays ≥11 s to take
   effect; the Arch dotfile-edit loop is ~0 s (mechanism difference, not a
   same-instrument pair). Incidental catch fixed live+repo: the
   `mate.mate-polkit` upstream rename warning.

3. **The niri "IPC spawn silently wedged" mystery is fully closed, with
   the mechanism refined at the source** (nix round 15 + 4.15 correction).
   4.15 had already identified the idle lock; tonight pinned the *actual*
   mechanism: a locked session's `do_action` gate drops non-whitelisted
   actions **pre-fork** (strace: zero clone/execve across all 22 niri
   threads; IPC replies `Handled` regardless — silent by design). Proven
   live on BOTH OSes tonight (positive + negative controls on Arch,
   negative + strace + v26.04-tag source on NixOS). Diagnostic one-liner
   for the future: `pgrep -x swaylock` (**corrected 2026-08-25 from `-f`,
   which also matches swayidle's arguments and always answers "locked"**).
   Bonus: the shipped brightness
   binds already use `allow-when-locked=true` — same gate, used right.

4. **4.17 package audit — the sweep the gpu-driver row demanded.** Four
   rows were lying (chromium, intel-media-driver, pipewire-jack — all
   installed tonight, plus a stray zero-dependency `jack2` replaced) and
   one was structurally broken: **`ttf-fragment-mono` does not exist as a
   package**; the working Fragment Mono is hand-dropped, package-unowned
   files in `~/.local/share/fonts/` (decision needed — see questions).
   Reverse direction: rejected terminals (alacritty/foot/ghostty) still
   installed → removed per the stale-loser rule; **fuzzel, swaybg, the
   screenshot stack, and brightnessctl were deployed-and-measured but
   rowless** → four recording rows added (flagged for your glance);
   **satty is installed but bound to nothing** (C4 annotate gap).

5. **4.18 — both protection rows now have exercised mechanisms.**
   *oom-protection:* systemd-oomd swap-kill canary PASSES — killed exactly
   the hog cgroup at >90% swap (13.7 G RAM + 7.3 G zram peak), kernel OOM
   never fired, zero thrash (5 s probe loop never stretched), instant
   recovery. Config left enabled on the box as a soak. *load-protection:*
   `CPUWeight=1` halves a 12-spinner hog's damage to kitty spawn
   (504→330 ms vs 141.6 baseline); the residual is **SMT sibling
   pollution, not frequency** (verified) — adding `AllowedCPUs` core
   reservation returns latency to baseline (**149.2 ms**). Row-ready
   recipe: weight + reserve a core or two; zero packages.

6. **fuzzel +1 ms post-nvidia: closed** (4.12 addendum) — fuzzel links and
   maps zero GL/EGL of any kind (pure cairo/pixman shm client), so the
   delta is compositor-side by elimination; ~1 ms, accepted cost.

7. **CHOICES.md format debt paid** (your documented preferred fix): seven
   prose Packages cells normalized, the merged browser/browser-fallback
   line split, `snapper, snap-pac` comma fixed, stale `linux-zen-headers`
   claim dropped, archinstall moved to Note. The installer awk now emits
   only real packages — with two remaining convention questions below.

8. **Repo furniture:** factual `README.md` added (pre-installer status
   stated honestly). LICENSE drafted but NOT committed (a rights grant is
   yours — see questions). `.gitignore` skipped: nothing to ignore yet.

9. **gradle recheck:** still 9.7.0-1, so `limine-snapper-sync` stays
   source-unbuildable; the binary-route question in the row is unchanged.

## The stale-premise pattern (process finding, fixed at the end of night)

Five tasks tonight started from resume.md/ledger lines that later files in
the same repo had already superseded (pytorch "never run", vapoursynth
"awaiting go-ahead" — you had declined it, 4.12 "write-up pending",
editor "phase 2 next" — all three phases were done and the row picked,
spawn-wedge "open" — 4.15 had closed it). Cost was small (one duplicate
test that turned out to add value), but the mechanism is real: same-day
sections accumulate and nothing marks them superseded.
**Fix applied: resume.md consolidated to one current-state block** (see the
resume) — and the lesson is recorded in nix round 14: read the tally
before claiming a task from one ledger row.

## Machine changes tonight (test box only; desktop untouched)

- Arch: +chromium +intel-media-driver +pipewire-jack (−jack2) +greetd
  (display-manager measurement, see below) −alacritty −foot −ghostty
  −yay-bin-debug; systemd-oomd enabled + two drop-ins (soak);
  all snapper-paired. Scratch: `~/t-*` scripts + `log-*` logs.
- NixOS: `~/.config/niri/config.kdl` polkit spawn line re-fixed (2nd
  silent clobber — history in the file header); `mate.mate-polkit` rename
  fixed in `/etc/nixos` + repo; torch venv left for inspection.
- Both flips used BootNext; box ends the night on Arch.

## Batched questions / decisions for the author

1. **Font delivery** (4.17): `ttf-fragment-mono` is dead; the font is
   unowned files. Recommend **vendoring the OFL TTFs in this repo**
   (license file alongside); alternatives: google-fonts megapackage, or
   curl-at-install. Pick one.
2. **Vendor-conditional Packages convention** (Phase-4 design): three
   cells still carry prose (`gpu-driver` Intel-conditional,
   `firmware-set` brace-list, `microcode` **or**; plus jupyter's
   venv-split). Column-per-vendor? Slot-name prefix? Your call.
3. **Status-cell spelling**: some rows write `**picked**` (bold) — the
   documented awk (`$5=="picked"`) silently drops niri and kitty from a
   generated list. Normalize the cells, or widen the awk?
4. **satty keybind** (C4 annotate gap): propose
   `Mod+Print { spawn-sh "grim -g \"$(slurp)\" - | satty -f -"; }`-shape
   binding in the Phase-4 keybind block — or your preferred chord.
5. **docker base row**: docker is installed and quota-governed but no row
   picks it. Write the row (full-install component)?
6. **LICENSE**: MIT draft ready (`Copyright (c) 2026 Charles Fry`) —
   confirm license choice and name, then it lands.
7. **nvidia-open-dkms → prebuilt `nvidia-open`?** The dkms rationale was
   "zen is primary"; zen is gone. Prebuilt drops the headers dep and the
   per-kernel-bump rebuild. One-word switch if you want it.
8. **fzf + lazygit** into the package list (LazyVim invokes both; p4-nvim
   NOTES finding #1) — or drop their keybinds.
9. **oom-protection / load-protection rows**: mechanisms proven (4.18).
   Ratify systemd-oomd (swap-kill config as tested) and record the
   weight+AllowedCPUs recipe?
10. **Editor draft startup cost**: the p4 draft measures ~160 ms vs the
    126.8 ms the LazyVim decision was made on (+33 ms from the two extras
    + venv-selector). Re-affirm or trim (candidates: markdownlint,
    markdown-preview).
11. **Upstream reports, your call**: (a) niri — `niri msg action` replies
    `Handled` for actions silently dropped while locked; (b) molten —
    `:e`-reload destroying outputs+kernel (mechanism pinned, upstream
    design). File either?
12. **greetd verdict**: numbers below (filled in after the measurement
    boots) — pick greetd vs getty-autologin for `display-manager`.
13. **playerctl/orca keybinds** (carried from midday): both halves turn
    out already resolved on the box — playerctl is installed (keybind-apps
    row), and the orca "bind" exists only as a comment in the live config
    (never enabled). Nothing to decide unless you want the comment gone.

## greetd measurement (display-manager) — RESULTS (full detail: `benchmarks/4.19.greetd.md`)

- **Resident: ~6.8 MB PSS, two processes, permanent** (`Restart=always`) —
  the re-rank's "~2 MB" was 3× light.
- **Boot: no detectable delta** (greetd 2.906/2.690 s vs autologin
  3.244/2.708 s — within-config spread exceeds the gap).
- Works first-try both boots (niri up, spawn canary PASS, polkit agent
  running). Session class becomes `greeter` → re-run screen-share
  acceptance before ever shipping greetd.
- Box reverted to getty-autologin (verified); greetd left installed but
  disabled pending your pick. **The trade: 6.8 MB forever buys a
  supervised session + (in the initial_session shape) a real greeter on
  logout; getty-autologin is 0 MB with an instant re-login loop instead.**

## MegaUltraBunny stretch block (after the normal-goal queue emptied, per your instruction)

Full detail + web catalog: **`docs/megaultrabunny-research.md`**. Seven
measured prototypes, screenshots in `benchmarks/raw/mub-*`:

- **Neon gradient focus ring** — niri-native, ZERO packages, same GPU pass
  as a solid ring (could even grace the default theme).
- **Custom window-open GLSL shader** — "neon materialize" scanline beam-in,
  compositor-native, zero packages; mid-animation frame captured.
- **GLSL synthwave wallpaper** (gpupaper, AUR): priced end-to-end —
  327 MB unpinned → **131 MB PSS + ~3% core with per-app ICD pins** (the
  Vulkan+EGL double-enumeration tax strikes again, decomposed).
- **kitten panel + cava**: audio-reactive neon spectrum desktop from
  software already in the rice (+cava from extra); fed synthetically — no
  audio was played at 00:30.
- **kitty cursor_trail**: zero idle cost, ~2× kitty GPU render only while
  the cursor moves.
- **Fork-free ASCII bunny flip-book player** — strace-proven 1 clone
  total (the `ascii-bunnies` row's design rule, demonstrated).
- **fastfetch bunny fetch**: 2.5 ms.
- **Palette pipeline verdict (also the C10 eval)**: matugen tones
  hand-picked colors under both config syntaxes → **envsubst templater
  wins** (exact colors, 2.3 ms, gettext is required-by base).
- **Window-close "de-rez" shader** — the open shader's companion, frame
  captured.
- **DankMaterialShell measured — the first mega-shell RAM number anyone
  has**: full bar first-try on niri, **~486 MB PSS (277.9 MB real anon
  heap), 0.0% idle CPU** fresh — MUB-affordable on 64 GB, categorically
  not default-theme material. Screenshot deposited.
- Composed scene shot: `benchmarks/raw/mub-composed-scene.png`.

## DA discipline

Nix rounds 14–17 (pytorch replication + Arch leg, rebuild timing, lock
gating) and Arch rounds 15–17 (4.18/4.19/4.20+palette,
`da-logs/overnight-2026-08-25.md`) — every overnight conclusion is gated;
concession edits applied in place. MUB numbers filed informational per the
4.12 precedent (they gate when a MUB row is proposed).

14. **Palette mechanism**: confirm the envsubst verdict so the Phase-4
    C10 row can be written (matugen/wallust measured out — see MUB doc).

## Machine changes — complete list (test box only)

Arch: +chromium +intel-media-driver +pipewire-jack (−jack2) +greetd
(disabled after measurement, kept for your verdict) +strace +fastfetch
+hyperfine +cava +matugen +gpupaper (AUR) +dms-shell (measured, not
running, kept for your play) −alacritty −foot −ghostty −yay-bin-debug;
systemd-oomd enabled + 2 drop-ins (soak); `~/mub/` playground (shaders,
logos, palette, player) + `~/t-*` scratch. All pacman ops
snapper-paired. strace/hyperfine are dev tools per the CLAUDE.md rule
(never ship); fastfetch/cava/matugen/gpupaper/dms-shell are MUB
candidates — keep or sweep, your call.
NixOS: niri polkit line re-fixed, mate-polkit rename fixed, torch venv
kept for inspection.

## Disk-alert soak (4-hourly)

- **00:00:30 firing: PASS** — ran 6 s, healthy-silent (disk 4%), no mako
  alert, timer rescheduled itself correctly (the 20:00 "LAST" was the
  previous boot's).
- **04:01:16 firing: PASS** — ran 3 s, healthy-silent, clean finish.
- **08:00:16 firing: PASS** — ran 3 s, healthy-silent, clean finish.

**Soak verdict: three consecutive unattended firings across a reboot and an
OS flip, zero false alerts, zero misses.** The draft timer behaves; what
remains for the row is your Phase-4 ratification of the alert design
itself (threshold 80, qgroup meters, snapper budget — per the p4-draft
commit).
