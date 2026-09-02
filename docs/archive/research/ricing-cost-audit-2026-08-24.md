# Research: ricing techniques audited against Fast/Light (2026-08-24, overnight)

Gathered by a research subagent (web survey), reviewed and filed by the
overnight session. Confidence flags are the agent's own; numbers are sourced
where the ecosystem publishes any (it mostly doesn't — that absence is itself
a finding). Actionable candidates for this repo are extracted at the bottom.

## 1. Color/theming pipelines

**pywal → wallust/matugen is a closed chapter.** pywal was archived 2024-04;
pywal16 is a compatibility fork. The live options are **wallust** (Rust,
native kmeans color extraction, no subprocess forks — built explicitly
because pywal's Python+imagemagick pipeline was perceptibly slow on a
wallpaper-change keybind) and **matugen** (Rust, Material-You algorithm,
templated output + per-target `post_hook`). All three are **template
generators, not daemons** — one-shot per palette change, zero resident cost.

Propagation mechanisms in the wild: wallust templates → output files → app
reloads via `SIGUSR1` (kitty) / `SIGUSR2` (waybar/ghostty); matugen's
`reload_apps_list` maps app → reload command (`makoctl reload`,
`niri msg action load-config-file`, etc.); waybar+swaync sharing one
generated CSS via `@import` (JaKooLit). Apps without a running instance need
nothing — they read the file on next launch.

Tags: pipeline [zero-cost resident]; palette change [one-shot: pywal slow,
wallust/matugen fast].

## 2. Status bars

- **No bar + niri's built-in overview (Mod+O)**: [zero-cost resident] — the
  compositor's own design intent; nothing runs until summoned.
- **yambar**: C, event-driven not polling, 0.41 MB installed — but upstream
  is archived ("NOT DEVELOPED ANYMORE"): a priority-1 problem.
- **waybar / ironbar / ags-astal / quickshell**: **nobody publishes real
  RSS/PSS numbers.** The only quantified-sounding comparison found is
  marketing copy. ags/quickshell's "one process instead of many" pitch is an
  architecture claim with no measurements attached. Treat every "bar X is
  lightweight" claim as unverified; measure locally if a bar is ever wanted.

## 3. Terminal eye candy with zero residents

- Prompt art, kitty tab_bar styling: [zero-cost] — render-time config.
- **fastfetch vs neofetch**: neofetch ~222 ms vs a C rewrite ~3 ms on the
  same machine (single-machine measurement) — a real per-terminal-open
  BUDGET bucket item, not noise. [per-event: ~ms vs ~200 ms]
- **Ligature-free fonts are a latency win, not just taste**: ~+1.2 ms/render
  reported for ligature shaping. Matches the repo's `font` row measurement
  (ligatures off saved 37 ms / 16% on the 200k-line flood).
- kitty `cursor_trail` (0.30+): GPU shader based; **no published frame-time
  numbers anywhere** — candidate for the rice, needs local measurement.
- **foot as the zero baseline**: ~21 MB reported; its `--server` mode is the
  same shape as kitty single-instance (banned here) — noted for context.

## 4. Wallpaper

The clearest sourced numbers in the whole survey:

- **swaybg**: long-lived process per output holding the decoded image; one
  (anecdotal, multi-monitor, huge image) report of >1.2 GB. Mechanism —
  per-output decode, uncompressed — explains bad scaling. [resident]
- **swww**: ~90 MB reported resident for a single static 1920×1200 image
  (possible transition-buffer leak). [resident, rejected]
- **mpvpaper/animated**: per-frame video decode forever. [resident, worst]
- **niri's native solid color**: no process, no decode. [zero-cost] — and
  "matte black base layer" is exactly a solid color.

## 5. Animations/blur/shadows

- Borders, gaps, rounded corners, opacity: drawn in a render pass that
  happens anyway. [zero-cost]
- **Hyprland blur**: "GPU 20% with blur, 1% without" (issue report); a
  laptop battery report of 5 h → 2 h under heavy blur; Hyprland's own wiki
  says disable blur to save battery.
- **niri 26.04 blur** (`ext-background-effect`): shipped in two explicit
  cost tiers — **x-ray blur** (computed once against the backdrop, shared;
  near-zero) vs **non-x-ray** (recomputed on every change; upstream's own
  docs call it significantly more expensive). Take the free tier or none.
- niri's stated philosophy prioritizes input latency over eye candy — a
  values match with priority 2a.

## 6. Notifications

No trustworthy steady-state numbers exist for mako/dunst/swaync — only leak
reports (dunst: one unconfirmed multi-GB heap report; swaync: confirmed
unbounded VRAM growth when toggling its control center). The actionable fact
is architectural: **mako has the smallest feature surface** = fewest places
for exactly these bugs. Validates the repo's `notifications` lean.

## 7. Login/boot eye candy

- **Plymouth: real boot cost.** ~8 s attributed to plymouth-quit-wait in one
  RH bug; a Fedora thread reports disabling it halved boot; pathological
  cases worse. [one-shot per boot, ~seconds] — reject for BunnE, or carry as
  an explicit stated trade if the author ever wants a splash.
- greetd+tuigreet vs autologin: no benchmark exists; the difference is a
  human-typing-bound prompt vs none. Security-vs-speed call, not a perf one.
- `quiet` kernel flag: console output has real time cost; near-free win.

## 8. Lock screens

Cleanest number in the report: **swaylock ~20 MB vs hyprlock 150-244 MB**
(same comparison thread; hyprlock's maintainer attributes it to the GPU
stack). swaylock-effects' blur is paid once at lock time and has an
`--effect-scale` knob. Validates the repo's `lock-idle` pick.

## 9. Matte black + neon + ASCII, minimal stack

No existing repo documents "matte black + neon + ASCII with zero residents
beyond the compositor" as a named goal — the pieces are individually
well-attested (niri solid backdrop, kitty/foot + fastfetch + ligature-free
font, wallust/matugen one-shot palette, no bar, swaylock on demand), but the
assembly is this repo's own synthesis. end-4/dots-hyprland is the named
anti-pattern (quickshell mega-shell, animated QML); JaKooLit is the best
reference for the propagation *mechanism* (not the footprint).

## Actionable candidates for this repo (filed by the session, not the agent)

1. ~~Verify then drop swaybg~~ — **REFUTED by direct test the same night**:
   `output { background-color }` validates on niri 26.04 but paints only the
   overview backdrop, not the workspace view (pixel-verified via grim: view
   stayed #404040 even set to #ff0000; with swaybg restored the pixel reads
   exactly #0f0f0f). `layout { background-color }` doesn't parse. swaybg's
   2.2 MB PSS stays justified; the `wallpaper` row's "niri alone draws flat
   grey" note remains true on 26.04.
2. **wallust or matugen as the Phase-4 palette generator** — one-shot Rust,
   exactly the C10 "one palette file, everything generated" shape. Bake off
   template quality, not daemons (neither is one).
3. **fastfetch allowed but budgeted** if any fetch art is wanted per
   terminal; neofetch rejected on measurement.
4. **Plymouth: reject** with the sourced ~seconds cost in the row.
5. **kitty cursor_trail**: candidate neon touch, zero published numbers —
   measure locally before adopting.
6. **niri x-ray blur only**, if blur is ever wanted for the rice.
7. Bar stays "none" — and any future bar proposal must bring its own PSS
   measurement, because upstream numbers do not exist.
