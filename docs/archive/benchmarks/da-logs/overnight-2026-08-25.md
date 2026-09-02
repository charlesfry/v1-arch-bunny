# DA log — overnight batch (rounds 15–17), 2026-08-25

Three conclusions from the unattended overnight session, gated together.
Each round ran fresh probes beyond the write-ups' inline disclosures; all
probe outputs are in the session transcript, decisive ones restated here.

## Round 15 — 4.18 (oom-protection + load-protection)

**Claims:** oomd swap-kill canary passes (kills exactly the hog cgroup,
kernel OOM silent, no thrash); CPUWeight halves interactive inflation
(504→330 ms vs 141.6 baseline); adding core reservation returns to
baseline (149.2 ms), residual attributed to SMT.

**Attacks:**
1. **Condition D changed TWO variables** — `AllowedCPUs=0,1,6,7` *and* the
   spinner count (4, not 12). "C vs D isolates SMT" therefore conflates
   core reservation with a lighter runqueue. **Conceded; 4.18 reworded**:
   the *recipe* claim (weight + reserved whole cores ⇒ baseline latency)
   stands on D as run; the *mechanism* split (scheduling share vs SMT) is
   indicated by the frequency probe (only ~7% clock loss) but not
   isolated — a clean D′ would confine 12 spinners to 4 CPUs.
2. **"Zero thrash" overstated**: the probe ticks were 5–6 s; one interval
   stretched to 6 s (t+45→t+51). **Conceded; reworded** to "no
   multi-second stalls; one tick stretched ≤1 s at peak."
3. Ordering warmth confound (D ran last; kitty pages warm): medians are
   warm-only by instrument design in every condition; delta magnitudes
   (3.6×) dwarf warmth effects. Noted, no change.
4. oomd: swap-kill path only; pressure path configured-unexercised;
   16 GB/zram-only box — all already disclosed in the write-up. The
   `--collect` Result-line instrument bug was disclosed at write time.

**Verdict: survives with caveats** — recipe and canary stand; mechanism
language coarsened in place.

## Round 16 — 4.19 (greetd)

**Claims:** greetd ≈6.8 MB PSS across two permanent processes; no boot
delta detectable (n=2v2); works first-try; class becomes `greeter`.

**Attacks:**
1. **The getty-path "respawns the session on exit" equivalence was
   reasoned, never tested.** **Fixed by probe tonight**: `pkill -x niri`
   on the getty-autologin config → fresh niri (new pid) up in <4 s via
   the autologin→`.bash_profile`-guard loop. Equivalence upgraded from
   inference to observation (n=1, clean-exit-shaped kill).
2. Session-holder greetd child (5.7 MB) measured minutes after boot only;
   growth over a day-long session unknown. **Added to 4.19 as an open
   note.** (greetd is a small Rust daemon; risk low, claim bounded.)
3. Portal/screen-share behavior under `class=greeter` untested — already
   flagged in the write-up as a pre-ship gate.
4. n=2v2 boot samples — no delta *claim* was made in either direction;
   phrasing already correct.

**Verdict: survives with caveats** — the missing control now exists; one
open note added.

## Round 17 — 4.20 (dir-aware-display) + the palette-pipeline verdict

**Claims:** hook hot path 9.3 µs/prompt, 33–37 µs on cd, zero forks;
matugen tones custom colors (unusable for a hand palette), envsubst wins
(exact colors, 2.3 ms, zero new packages).

**Attacks:**
1. **"matugen mangles colors" could have been a config-syntax artifact**
   (inline-table `blend = false` silently ignored?). **Probed tonight
   with the explicit `[config.custom_colors.bunne_pink]` table syntax:
   still `#fab1d9`.** Two syntaxes, same toning — refutation hardened,
   not artifact.
2. **"Zero new packages" for envsubst** — verified: `gettext` is
   `Required By: base … pacman` on this box; it exists on any Arch
   install by construction.
3. 9.3 µs is the *function* cost in a tight loop, not the integrated
   PROMPT_COMMAND-dispatch cost; and the OSC write's downstream cost
   (kitty processing a title change) lands outside the shell measurement,
   per directory change only. At these magnitudes (0.1% of the prompt)
   neither moves the conclusion; noted in 4.20.
4. 3-entry map; a realistic 20-entry map scales the *cd-path* scan
   linearly (~10× of 37 µs worst case ≈ 0.4 ms per cd) — still trivial;
   noted.

**Verdict: survives** — with the syntax-artifact hole closed by probe and
two magnitude notes added.

**MUB measurements (gradient ring, cursor trail, shader wall, flip-book,
fastfetch, cava panel)**: filed as informational per the 4.12 precedent —
rice measurements feeding no ledger decision tonight; each carries its raw
artifact. They enter the gate when a MUB row is actually proposed.
